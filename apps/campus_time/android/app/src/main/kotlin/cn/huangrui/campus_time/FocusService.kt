package cn.huangrui.campus_time

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.ScrollView

class FocusService : AccessibilityService() {
    companion object { var current: FocusService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private var overlay: View? = null
    private var wake: PowerManager.WakeLock? = null
    private var allowed: Set<String> = emptySet()
    private var foreground: String? = null
    private var receiver: FocusReceiver? = null
    private val loop = object : Runnable {
        override fun run() {
            safely {
                val store = FocusStore.get(this@FocusService)
                store.heartbeat()
                if (store.fault != null || store.active() == null) { hideOverlay(); releaseWake() }
                else { keepAwake(); enforce(foreground) }
            }
            handler.postDelayed(this,1_000)
        }
    }
    override fun onServiceConnected() {
        current = this
        allowed = FocusApps.mandatory(this)
        safely { FocusStore.get(this) }
        receiver = FocusReceiver().also {
            val filter = android.content.IntentFilter().apply {
                addAction(Intent.ACTION_TIME_CHANGED); addAction(Intent.ACTION_TIMEZONE_CHANGED)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            if (Build.VERSION.SDK_INT >= 33) registerReceiver(it,filter,Context.RECEIVER_NOT_EXPORTED)
            else registerReceiver(it,filter)
        }
        handler.post(loop)
    }
    private fun keepAwake() {
        if (wake?.isHeld == true) return
        wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"campus_time:focus").apply {
            setReferenceCounted(false); acquire(4 * 60 * 60 * 1_000L)
        }
    }
    private fun releaseWake() { if(wake?.isHeld == true) wake?.release(); wake = null }
    private fun safely(block: () -> Unit) {
        try { block() } catch (error: Exception) {
            runCatching {
                if (error is android.database.sqlite.SQLiteException) FocusStore.get(this).failSafe()
                else FocusStore.get(this).end("service_error")
            }
            hideOverlay(); releaseWake()
        }
    }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        // Overlay events must not dismiss the overlay itself.
        if (pkg == packageName && overlay != null && event.className?.toString() != MainActivity::class.java.name) return
        foreground = pkg
        safely { allowed = FocusApps.mandatory(this); enforce(pkg) }
    }
    private fun enforce(pkg: String?) {
        val store = FocusStore.get(this)
        if (store.fault != null || store.active() == null || (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) {
            hideOverlay(); return
        }
        if (pkg == null) return
        if (pkg in allowed || pkg in store.whitelist()) hideOverlay() else showOverlay()
    }
    private fun showOverlay() {
        if (overlay != null) return
        val pad = (24*resources.displayMetrics.density).toInt()
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            setPadding(pad,pad,pad,pad); setBackgroundColor(Color.rgb(247,248,243))
            addView(TextView(this@FocusService).apply {
                text = "正在专注\n此应用不在白名单中"; textSize = 25f
                gravity = Gravity.CENTER; setTextColor(Color.rgb(33,59,55))
            })
            addView(TextView(this@FocusService).apply {
                text = "返回课间，或从桌面打开允许使用的应用。\n电话、系统设置和安全退出始终可用。"
                textSize = 15f; gravity = Gravity.CENTER; setPadding(0,pad,0,pad)
                setTextColor(Color.DKGRAY)
            })
            fun button(label: String, click: () -> Unit) { addView(Button(this@FocusService).apply { text = label; setOnClickListener { click() } }) }
            button("返回课间") { launch(Intent(this@FocusService,MainActivity::class.java)) }
            button("返回桌面") { performGlobalAction(GLOBAL_ACTION_HOME); hideOverlay(); foreground = null }
            button("拨打电话 / 紧急求助") { launch(Intent(Intent.ACTION_DIAL)) }
            button("系统设置 / 撤销权限") { launch(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
            button("安全解除限制（记为中断）") {
                safely { FocusStore.get(this@FocusService).end("safety_exit") }
                hideOverlay(); releaseWake(); foreground = null
            }
        }
        val params = WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT,WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,PixelFormat.OPAQUE)
        // System status/navigation bars and emergency controls remain accessible.
        val scroll = ScrollView(this).apply { isFillViewport = true; addView(layout) }
        (getSystemService(WINDOW_SERVICE) as WindowManager).addView(scroll,params)
        overlay = scroll
    }
    private fun launch(intent: Intent) {
        hideOverlay(); foreground = null
        runCatching { startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)) }
    }
    fun hideOverlay() {
        val view = overlay ?: return
        overlay = null
        runCatching { (getSystemService(WINDOW_SERVICE) as WindowManager).removeViewImmediate(view) }
    }
    fun completed() {
        hideOverlay(); releaseWake()
        if (!FocusStore.get(this).remindersEnabled()) return
        runCatching {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            if(Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(NotificationChannel("focus_complete","专注完成",NotificationManager.IMPORTANCE_DEFAULT))
            val builder = if(Build.VERSION.SDK_INT >= 26) Notification.Builder(this,"focus_complete") else Notification.Builder(this)
            val open = PendingIntent.getActivity(this,810,Intent(this,MainActivity::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            nm.notify(810,builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm).setContentTitle("专注完成")
                .setContentText("应用限制已解除，休息一下吧。").setContentIntent(open).setAutoCancel(true).build())
        }
    }
    override fun onInterrupt() { safely { FocusStore.get(this).end("service_interrupted") }; hideOverlay(); releaseWake() }
    override fun onUnbind(intent: Intent?): Boolean {
        safely { FocusStore.get(this).end("permission_revoked") }; cleanup(); return super.onUnbind(intent)
    }
    private fun cleanup() {
        handler.removeCallbacks(loop); hideOverlay(); releaseWake()
        receiver?.let { runCatching { unregisterReceiver(it) } }; receiver = null
        if(current === this) current = null
    }
    override fun onDestroy() {
        safely { FocusStore.get(this).end("service_stopped") }; cleanup(); super.onDestroy()
    }
}
