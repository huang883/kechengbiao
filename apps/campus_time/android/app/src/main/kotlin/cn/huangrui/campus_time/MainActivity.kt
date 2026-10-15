package cn.huangrui.campus_time
import android.content.Intent
import android.database.sqlite.SQLiteException
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"campus_time/focus").setMethodCallHandler { call, result ->
            try {
                val store = FocusStore.get(this)
                when(call.method) {
                    "status" -> result.success(store.status())
                    "consent" -> { store.consent(); result.success(null) }
                    "settings" -> { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); result.success(null) }
                    "start" -> { store.setReminders(call.argument<Boolean>("notify") ?: true); store.start((call.argument<Number>("planned") ?: 0).toLong()); result.success(store.status()) }
                    "pause" -> { store.pause(true); result.success(store.status()) }
                    "resume" -> { store.pause(false); result.success(store.status()) }
                    "armExit" -> result.success(store.armExit())
                    "cancelExit" -> { store.cancelExit(call.argument<String>("token") ?: ""); result.success(null) }
                    "confirmExit" -> { store.confirmExit(call.argument<String>("token") ?: ""); result.success(store.status()) }
                    "safetyExit" -> { store.end("safety_exit"); result.success(store.status()) }
                    "reminders" -> { store.setReminders(call.argument<Boolean>("enabled") ?: true); result.success(null) }
                    "history" -> result.success(store.history())
                    "apps" -> {
                        store.prune(FocusApps.installed(this).map { it.activityInfo.packageName }.toSet())
                        val selected = store.whitelist()
                        Thread {
                            try { val apps = FocusApps.list(applicationContext,selected); runOnUiThread { result.success(apps) } }
                            catch(_: Exception) { runOnUiThread { result.error("apps","无法读取应用列表",null) } }
                        }.start()
                    }
                    "whitelist" -> {
                        val installed = FocusApps.installed(this).map { it.activityInfo.packageName }.toSet()
                        store.setWhitelist((call.argument<List<String>>("packages") ?: emptyList()).toSet().intersect(installed))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch(e: Exception) {
                if(e is SQLiteException) runCatching { FocusStore.get(this).failSafe() }
                result.error("focus",e.message ?: "专注操作失败，请重试",null)
            }
        }
    }
}
