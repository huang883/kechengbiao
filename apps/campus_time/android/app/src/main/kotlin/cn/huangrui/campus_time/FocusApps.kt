package cn.huangrui.campus_time
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.provider.Settings
import android.telecom.TelecomManager
import android.view.inputmethod.InputMethodManager
import java.io.ByteArrayOutputStream
object FocusApps {
    fun mandatory(context: Context): Set<String> = buildSet {
        add(context.packageName)
        addAll(listOf("android","com.android.systemui","com.android.settings","com.android.phone","com.android.server.telecom",
            "com.android.permissioncontroller","com.google.android.permissioncontroller","com.android.emergency","com.android.packageinstaller","com.google.android.packageinstaller"))
        val pm = context.packageManager
        listOf(Intent(Intent.ACTION_DIAL),Intent("android.intent.action.EMERGENCY_DIAL"),Intent("android.intent.action.CALL_EMERGENCY"),Intent(Settings.ACTION_SETTINGS),Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS),
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)).forEach { intent ->
            pm.queryIntentActivities(intent,0).forEach { add(it.activityInfo.packageName) }
        }
        (context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager).defaultDialerPackage?.let { add(it) }
        (context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).enabledInputMethodList.forEach { add(it.packageName) }
    }
    fun installed(context: Context): List<android.content.pm.ResolveInfo> = context.packageManager.queryIntentActivities(
        Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER),0).distinctBy { it.activityInfo.packageName }
    fun list(context: Context, selected: Set<String>): List<Map<String, Any?>> {
        val pm = context.packageManager
        val required = mandatory(context)
        return installed(context).map { app ->
            val pkg = app.activityInfo.packageName
            val icon = runCatching {
                val drawable = app.loadIcon(pm)
                val bitmap = Bitmap.createBitmap(64,64,Bitmap.Config.ARGB_8888)
                drawable.setBounds(0,0,64,64); drawable.draw(Canvas(bitmap))
                ByteArrayOutputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it); bitmap.recycle(); it.toByteArray() }
            }.getOrNull()
            mapOf("package" to pkg, "name" to app.loadLabel(pm).toString(), "icon" to icon,
                "selected" to (pkg in selected || pkg in required), "mandatory" to (pkg in required))
        }.sortedBy { it["name"].toString() }
    }
}
