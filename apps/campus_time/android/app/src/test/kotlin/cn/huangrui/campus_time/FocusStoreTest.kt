package cn.huangrui.campus_time

import android.content.Context
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.SQLiteMode
import java.time.Instant
import java.time.ZoneId

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
@SQLiteMode(SQLiteMode.Mode.LEGACY)
class FocusStoreTest {
    private lateinit var store: FocusStore
    private lateinit var context: Context
    private var elapsed = 100_000L
    private var wall = Instant.parse("2026-10-15T02:00:00Z").toEpochMilli()
    private var zone = ZoneId.of("Asia/Shanghai")
    private val name = "focus_test.sqlite"
    private fun open() = FocusStore(context,{elapsed},{wall},{zone},{true},name)
    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        context.deleteDatabase(name)
        store = open(); store.consent()
    }
    @After fun close() { if (::store.isInitialized) store.close(); context.deleteDatabase(name) }
    private fun step(ms: Long) { elapsed+=ms; wall+=ms; store.heartbeat() }
    private fun session() = (store.history()["sessions"] as List<*>).first() as Map<*,*>
    private fun endEarly() { store.start(60_000); val token=store.armExit(); step(5_000); store.confirmExit(token) }
    private fun fails(block: () -> Unit) { try {block();fail("Expected rejection")} catch(_: IllegalStateException) {} }
    @Test fun fiveSecondsAndDuplicateRequests() {
        store.start(60_000); val token=store.armExit()
        step(4_999); fails {store.confirmExit(token)}; assertEquals(2,store.remaining())
        step(1);store.confirmExit(token);store.confirmExit(token)
        assertEquals(1,store.remaining());assertEquals("early_exit",session()["state"])
        assertEquals(5_000L,session()["restricted_ms"])
    }
    @Test fun cancelledGateAndReopenRequireNewFiveSeconds() {
        store.start(60_000);val first=store.armExit();step(4_000);store.cancelExit(first)
        val next=store.armExit();step(1_000);fails {store.confirmExit(next)};fails {store.confirmExit(first)}
        assertEquals(2,store.remaining());step(4_000);store.confirmExit(next);assertEquals(1,store.remaining())
    }
    @Test fun twoExitsThenNewMonth() {
        endEarly();endEarly();assertEquals(0,store.remaining())
        store.start(60_000);fails {store.armExit()};store.end("safety_exit")
        wall=Instant.parse("2026-11-01T00:00:00Z").toEpochMilli()
        assertEquals(2,store.remaining());endEarly();assertEquals(1,store.remaining())
        wall=Instant.parse("2026-10-20T00:00:00Z").toEpochMilli();assertEquals(0,store.remaining())
    }
    @Test fun naturalCompletionDoesNotConsumeAndPauseStillRestricts() {
        store.start(60_000);step(10_000);store.pause(true);step(10_000);store.pause(false)
        repeat(5){step(10_000)}
        assertEquals("completed",session()["state"]);assertEquals(60_000L,session()["timer_ms"])
        assertEquals(70_000L,session()["restricted_ms"]);assertEquals(2,store.remaining())
    }
    @Test fun processRestartPreservesQuotaAndInterruptsActiveSession() {
        endEarly();store.start(60_000);step(1_000);store.close();store=open()
        assertNull(store.active());assertEquals(1,store.remaining());assertEquals("process_interrupted",session()["state"])
    }
    @Test fun gapsClockChangesAndPermissionLossNeverComplete() {
        store.start(60_000);step(1_000);step(20_000)
        assertEquals("clock_or_service_gap",session()["state"]);assertEquals(1_000L,session()["timer_ms"])
        store.start(60_000);wall+=60_000;store.heartbeat();assertEquals("clock_or_service_gap",session()["state"])
        store.start(60_000);zone=ZoneId.of("UTC");store.heartbeat();assertEquals("clock_or_service_gap",session()["state"])
        store.start(60_000);store.end("permission_revoked");assertEquals(2,store.remaining())
    }
    @Test fun databaseFailureRollsBackQuotaAndSessionTogether() {
        store.start(60_000);val token=store.armExit();step(5_000)
        store.writableDatabase.execSQL("CREATE TRIGGER fail_end BEFORE UPDATE ON sessions WHEN NEW.state='early_exit' BEGIN SELECT RAISE(ABORT,'simulated full storage'); END")
        try { store.confirmExit(token);fail("Expected database failure") } catch(_: android.database.sqlite.SQLiteException) {}
        assertEquals(2,store.remaining());assertNotNull(store.active())
        store.writableDatabase.execSQL("DROP TRIGGER fail_end")
        store.confirmExit(token);assertEquals(1,store.remaining())
    }
    @Test fun whitelistPersistsAndPrunesUninstalled() {
        store.setWhitelist(setOf("a","b"));store.close();store=open();assertEquals(setOf("a","b"),store.whitelist())
        store.prune(setOf("b"));assertEquals(setOf("b"),store.whitelist())
        store.start(60_000);fails {store.setWhitelist(setOf("c"))}
    }
    @Test fun repeatedStartCreatesOnlyOneSessionAndRejectsWrongToken() {
        repeat(10) { store.start(60_000) }
        assertEquals(1,(store.history()["sessions"] as List<*>).size)
        store.armExit();step(5_000);fails {store.confirmExit("wrong-token")}
        assertEquals(2,store.remaining())
    }
    @Test fun confirmAcrossMonthUsesConfirmationMonthAndTimeZoneChangesInterrupt() {
        wall=Instant.parse("2026-10-31T15:59:58Z").toEpochMilli()
        store.start(60_000);val token=store.armExit();step(5_000);store.confirmExit(token)
        assertEquals("2026-11",store.month());assertEquals(1,store.remaining())
        wall=Instant.parse("2026-10-30T02:00:00Z").toEpochMilli();assertEquals(2,store.remaining())
    }
    @Test fun policyUsesMonotonicTime() {
        assertFalse(FocusPolicy.exitReady(10_000,9_000));assertFalse(FocusPolicy.exitReady(10_000,14_999))
        assertTrue(FocusPolicy.exitReady(10_000,15_000));assertFalse(FocusPolicy.validInterval(1000,60000))
    }
}
