package cn.huangrui.campus_time

/** Pure rules shared by the service and JVM tests. No wall clock for elapsed time. */
object FocusPolicy {
    const val EXIT_DELAY_MS = 5_000L
    const val MAX_HEARTBEAT_GAP_MS = 15_000L
    fun exitReady(armed: Long, now: Long) = now >= armed && now - armed >= EXIT_DELAY_MS
    fun remaining(used: Int) = (2 - used).coerceIn(0, 2)
    fun validInterval(elapsed: Long, wall: Long) = elapsed in 0..MAX_HEARTBEAT_GAP_MS && kotlin.math.abs(elapsed - wall) <= 2_000
}
