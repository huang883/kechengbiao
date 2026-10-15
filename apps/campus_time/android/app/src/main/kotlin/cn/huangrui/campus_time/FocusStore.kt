package cn.huangrui.campus_time

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.SystemClock
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID

/** All access is on the Android main looper; SQLite transactions are still the authority. */
class FocusStore internal constructor(private val context: Context,
    private val elapsedNow: () -> Long = { SystemClock.elapsedRealtime() },
    private val wallNow: () -> Long = { System.currentTimeMillis() },
    private val zoneNow: () -> ZoneId = { ZoneId.systemDefault() },
    private val ready: () -> Boolean = { FocusService.current != null },
    databaseName: String = "focus.sqlite"
) : SQLiteOpenHelper(context, databaseName, null, 1) {
    companion object {
        private var instance: FocusStore? = null
        @Synchronized fun get(context: Context): FocusStore = instance ?: FocusStore(context.applicationContext).also { instance = it }
    }
    private val prefs = context.getSharedPreferences("focus_safety", Context.MODE_PRIVATE)
    var fault: String? = null
        private set
    private var gate: Triple<String, String, Long>? = null
    init {
        // A new OS process cannot prove continuous enforcement since the last checkpoint.
        val recoveryReason = if (prefs.getBoolean("recovery_required",false)) "storage_error" else "process_interrupted"
        writableDatabase.execSQL("UPDATE sessions SET state=?, ended=last_wall WHERE state IN ('running','paused')",arrayOf(recoveryReason))
        prefs.edit().remove("recovery_required").commit()
    }
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""CREATE TABLE sessions(id TEXT PRIMARY KEY, started INTEGER NOT NULL, ended INTEGER,
            planned INTEGER NOT NULL, timer_ms INTEGER NOT NULL DEFAULT 0, restricted_ms INTEGER NOT NULL DEFAULT 0,
            state TEXT NOT NULL, consumed INTEGER NOT NULL DEFAULT 0, last_elapsed INTEGER NOT NULL,
            last_wall INTEGER NOT NULL, zone TEXT NOT NULL, active_slot INTEGER NOT NULL DEFAULT 1 CHECK(active_slot=1))""")
        db.execSQL("CREATE UNIQUE INDEX one_active ON sessions(active_slot) WHERE state IN ('running','paused')")
        db.execSQL("""CREATE TABLE segments(id INTEGER PRIMARY KEY AUTOINCREMENT, session_id TEXT NOT NULL,
            start INTEGER NOT NULL, end INTEGER NOT NULL, timer_ms INTEGER NOT NULL, restricted_ms INTEGER NOT NULL,
            paused INTEGER NOT NULL, FOREIGN KEY(session_id) REFERENCES sessions(id))""")
        db.execSQL("CREATE INDEX segment_session ON segments(session_id)")
        db.execSQL("""CREATE TABLE exits(session_id TEXT PRIMARY KEY, month TEXT NOT NULL, at INTEGER NOT NULL,
            timer_ms INTEGER NOT NULL, restricted_ms INTEGER NOT NULL, FOREIGN KEY(session_id) REFERENCES sessions(id))""")
        db.execSQL("CREATE INDEX exit_month ON exits(month)")
        db.execSQL("CREATE TABLE whitelist(package TEXT PRIMARY KEY)")
    }
    override fun onConfigure(db: SQLiteDatabase) { db.setForeignKeyConstraintsEnabled(true) }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) { error("Unsupported focus database migration") }
    private fun rows(sql: String, args: Array<String> = emptyArray()): List<Map<String, Any?>> = readableDatabase.rawQuery(sql, args).use { c ->
        buildList { while (c.moveToNext()) add(c.columnNames.mapIndexed { i, name -> name to when(c.getType(i)) {
            android.database.Cursor.FIELD_TYPE_NULL -> null
            android.database.Cursor.FIELD_TYPE_INTEGER -> c.getLong(i)
            else -> c.getString(i)
        } }.toMap()) }
    }
    fun active(): Map<String, Any?>? = rows("SELECT * FROM sessions WHERE state IN ('running','paused') LIMIT 1").firstOrNull()
    private fun n(s: Map<String, Any?>, key: String) = (s[key] as Number).toLong()
    fun month() = YearMonth.from(java.time.Instant.ofEpochMilli(wallNow()).atZone(zoneNow())).toString()
    fun remaining() = FocusPolicy.remaining((rows("SELECT COUNT(*) AS used FROM exits WHERE month=?", arrayOf(month())).single()["used"] as Number).toInt())
    fun status(): Map<String, Any?> = mapOf("active" to active(), "remaining" to remaining(), "month" to month(),
        "ready" to (ready() && fault == null), "consent" to prefs.getBoolean("consent", false), "fault" to fault,
        "today" to today(), "latest" to rows("SELECT * FROM sessions ORDER BY started DESC, rowid DESC LIMIT 1").firstOrNull())
    private fun today(): Map<String, Any?> {
        val zone = zoneNow()
        val start = java.time.Instant.ofEpochMilli(wallNow()).atZone(zone).toLocalDate().atStartOfDay(zone).toInstant().toEpochMilli()
        val end = java.time.Instant.ofEpochMilli(wallNow()).atZone(zone).toLocalDate().plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val count = rows("SELECT COUNT(*) AS count FROM sessions WHERE state='completed' AND ended>=? AND ended<?",arrayOf(start.toString(),end.toString())).single()["count"]
        val segments = rows("SELECT g.* FROM segments g JOIN sessions s ON s.id=g.session_id WHERE s.state='completed' AND g.end>? AND g.start<?",arrayOf(start.toString(),end.toString()))
        val ms = segments.sumOf { g ->
            val a = n(g,"start"); val b = n(g,"end"); val t = n(g,"timer_ms")
            if(b<=a) 0L else t * (minOf(b,end)-a)/(b-a) - t * (maxOf(a,start)-a)/(b-a)
        }
        return mapOf("count" to count, "ms" to ms)
    }
    fun consent() { check(prefs.edit().putBoolean("consent", true).commit()) { "无法保存授权说明" } }
    fun remindersEnabled() = prefs.getBoolean("notify",true)
    fun setReminders(enabled: Boolean) { prefs.edit().putBoolean("notify",enabled).apply() }
    fun start(planned: Long) {
        check(fault == null) { "存储异常，请重启课间后重试" }
        check(ready() && prefs.getBoolean("consent", false)) { "请先阅读说明并开启课间专注辅助功能" }
        require(planned in 60_000..10_800_000) { "专注时长需为1—180分钟" }
        if (active() != null) return
        val now = wallNow()
        writableDatabase.execSQL("INSERT INTO sessions(id,started,planned,state,last_elapsed,last_wall,zone) VALUES(?,?,?,'running',?,?,?)",
            arrayOf(UUID.randomUUID().toString(), now, planned, elapsedNow(), now, zoneNow().id))
        gate = null
    }
    private fun <T> transaction(block: (SQLiteDatabase) -> T): T {
        val db = writableDatabase
        db.beginTransaction()
        try { val result = block(db); db.setTransactionSuccessful(); return result } finally { db.endTransaction() }
    }
    fun heartbeat() {
        if (fault != null) return
        val s = active() ?: return
        val elapsed = elapsedNow()
        val wall = wallNow()
        val dt = elapsed - n(s, "last_elapsed")
        if (!FocusPolicy.validInterval(dt, wall - n(s,"last_wall")) || s["zone"] != zoneNow().id) {
            end("clock_or_service_gap"); return
        }
        if (dt == 0L) return
        val paused = s["state"] == "paused"
        val credited = if (paused) dt else minOf(dt, n(s,"planned") - n(s,"timer_ms"))
        val timer = if (paused) 0L else credited
        val endWall = n(s,"last_wall") + credited
        val done = !paused && n(s,"timer_ms") + timer >= n(s,"planned")
        transaction { db ->
            val last = rows("SELECT * FROM segments WHERE session_id=? ORDER BY id DESC LIMIT 1", arrayOf(s["id"].toString())).firstOrNull()
            if (last != null && n(last,"end") == n(s,"last_wall") && n(last,"paused") == (if (paused) 1L else 0L)) {
                db.execSQL("UPDATE segments SET end=?,timer_ms=timer_ms+?,restricted_ms=restricted_ms+? WHERE id=?", arrayOf(endWall,timer,credited,last["id"]))
            } else {
                db.execSQL("INSERT INTO segments(session_id,start,end,timer_ms,restricted_ms,paused) VALUES(?,?,?,?,?,?)",
                    arrayOf(s["id"],n(s,"last_wall"),endWall,timer,credited,if(paused) 1 else 0))
            }
            db.execSQL("UPDATE sessions SET timer_ms=timer_ms+?,restricted_ms=restricted_ms+?,last_elapsed=?,last_wall=?,state=?,ended=? WHERE id=?",
                arrayOf(timer,credited,elapsed,endWall,if(done) "completed" else s["state"],if(done) endWall else null,s["id"]))
        }
        if (done) { gate = null; FocusService.current?.completed() }
    }
    fun pause(paused: Boolean) {
        heartbeat()
        val s = active() ?: return
        writableDatabase.execSQL("UPDATE sessions SET state=? WHERE id=?", arrayOf(if(paused) "paused" else "running",s["id"]))
    }
    fun end(reason: String) {
        val s = active() ?: return
        writableDatabase.execSQL("UPDATE sessions SET state=?,ended=last_wall WHERE id=?", arrayOf(reason,s["id"]))
        gate = null
        FocusService.current?.hideOverlay()
    }
    fun armExit(): String {
        val s = active() ?: error("本次专注已结束")
        check(remaining() > 0) { "本月提前退出机会已用完" }
        val token = UUID.randomUUID().toString()
        gate = Triple(s["id"].toString(),token,elapsedNow())
        return token
    }
    fun cancelExit(token: String) { if (gate?.second == token) gate = null }
    fun confirmExit(token: String) {
        heartbeat()
        val s = active() ?: return // Idempotent after completion or a previously committed exit.
        val g = gate ?: error("请重新打开退出确认窗口")
        check(g.first == s["id"] && g.second == token && FocusPolicy.exitReady(g.third,elapsedNow())) { "请等待完整5秒后确认" }
        transaction { db ->
            check(remaining() > 0) { "本月提前退出机会已用完" }
            db.execSQL("INSERT INTO exits(session_id,month,at,timer_ms,restricted_ms) VALUES(?,?,?,?,?)",
                arrayOf(s["id"],month(),wallNow(),s["timer_ms"],s["restricted_ms"]))
            db.execSQL("UPDATE sessions SET state='early_exit',consumed=1,ended=last_wall WHERE id=? AND state IN ('running','paused')",arrayOf(s["id"]))
        }
        gate = null
        FocusService.current?.hideOverlay()
    }
    fun history(): Map<String, Any?> = mapOf("sessions" to rows("SELECT * FROM sessions ORDER BY started DESC, rowid DESC"), "segments" to rows("SELECT * FROM segments ORDER BY start"))
    fun whitelist(): Set<String> = rows("SELECT package FROM whitelist").map { it["package"].toString() }.toSet()
    fun setWhitelist(packages: Set<String>) {
        check(active() == null) { "请在本次专注结束后修改白名单" }
        transaction { db ->
            db.delete("whitelist",null,null)
            packages.forEach { db.insertOrThrow("whitelist",null,ContentValues().apply { put("package",it) }) }
        }
    }
    fun prune(installed: Set<String>) {
        (whitelist() - installed).forEach { writableDatabase.delete("whitelist","package=?",arrayOf(it)) }
    }
    fun failSafe() {
        fault = "专注存储异常，已解除限制；请检查存储空间并重启课间。"
        // Even when SQLite cannot be written, the overlay must never remain locked.
        prefs.edit().putBoolean("recovery_required",true).commit()
        runCatching { end("storage_error") }
        FocusService.current?.hideOverlay()
    }
}
