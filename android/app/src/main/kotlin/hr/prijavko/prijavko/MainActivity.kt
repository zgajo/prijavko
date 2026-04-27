package hr.prijavko.prijavko

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hr.prijavko.window_secure"
        ).setMethodCallHandler { call, result ->
            // WHY runOnUiThread: MethodChannel handlers run on the platform
            // thread; Window.setFlags / clearFlags must be called on the UI
            // thread on some OEMs (CalledFromWrongThreadException otherwise).
            when (call.method) {
                "enable" -> runOnUiThread {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(null)
                }
                "disable" -> runOnUiThread {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
