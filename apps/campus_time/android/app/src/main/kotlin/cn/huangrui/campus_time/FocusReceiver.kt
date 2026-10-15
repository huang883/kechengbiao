package cn.huangrui.campus_time
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
class FocusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if(intent.action == Intent.ACTION_SCREEN_OFF) { FocusService.current?.hideOverlay(); return }
        runCatching { FocusStore.get(context).end(when(intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> "device_restarted"
            Intent.ACTION_MY_PACKAGE_REPLACED -> "app_updated"
            else -> "clock_changed"
        }) }.onFailure { runCatching { FocusStore.get(context).failSafe() } }
        FocusService.current?.hideOverlay()
    }
}
