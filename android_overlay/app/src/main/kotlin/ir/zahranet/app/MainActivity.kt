package ir.zahranet.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "zahranet/vpn").setMethodCallHandler { call, res ->
            when (call.method) {
                "isIrancell" -> res.success(isIrancell())
                "status" -> res.success(AetherVpnService.state)
                "stats" -> res.success(try { hev.htproxy.TProxyService.TProxyGetStats().toList() } catch (e: Throwable) { listOf(0L, 0L, 0L, 0L) })
                "prepare" -> {
                    val i = VpnService.prepare(this)
                    if (i == null) res.success(true) else { pending = res; startActivityForResult(i, 77) }
                }
                "start" -> {
                    if (!isIrancell()) { res.success(false); return@setMethodCallHandler }
                    val i = Intent(this, AetherVpnService::class.java)
                        .putExtra("mode", call.argument<String>("mode") ?: "--masque")
                    startForegroundService(i); res.success(true)
                }
                "stop" -> {
                    startService(Intent(this, AetherVpnService::class.java).setAction("stop")); res.success(true)
                }
                else -> res.notImplemented()
            }
        }
    }

    // Irancell = MCC 432, MNC 35 (SIM operator code, no permission needed)
    private fun isIrancell(): Boolean {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        return tm.simOperator == "43235"
    }

    override fun onActivityResult(r: Int, c: Int, d: Intent?) {
        super.onActivityResult(r, c, d)
        if (r == 77) { pending?.success(c == Activity.RESULT_OK); pending = null }
    }
}
