package ir.zahranet.app

import android.app.*
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import hev.htproxy.TProxyService
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket

class AetherVpnService : VpnService() {
    companion object { @Volatile var state = "off" }

    private var proc: Process? = null
    private var tun: ParcelFileDescriptor? = null
    private val socksPort = 1819

    override fun onStartCommand(i: Intent?, f: Int, id: Int): Int {
        if (i?.action == "stop") { stopAll(); return START_NOT_STICKY }
        if (state != "off") return START_STICKY
        startForeground(1, notification())
        state = "connecting"
        val mode = i?.getStringExtra("mode") ?: "--masque"
        Thread { run(mode) }.start()
        return START_STICKY
    }

    private fun run(mode: String) {
        try {
            // Core is shipped as jniLibs/arm64-v8a/libaether.so so Android extracts it as executable.
            val core = File(applicationInfo.nativeLibraryDir, "libaether.so")
            if (!core.exists()) throw IllegalStateException("libaether.so missing")
            proc = ProcessBuilder(core.path, mode, "--stats")
                .directory(filesDir).redirectErrorStream(true).start()
            // Drain output so the process never blocks.
            Thread { proc?.inputStream?.bufferedReader()?.forEachLine { } }.start()

            // SOCKS5 opens only after the core verified the tunnel.
            val end = System.currentTimeMillis() + 90_000
            var up = false
            while (System.currentTimeMillis() < end && proc?.isAlive == true) {
                try { Socket().use { it.connect(InetSocketAddress("127.0.0.1", socksPort), 400) }; up = true; break }
                catch (_: Exception) { Thread.sleep(500) }
            }
            if (!up) throw IllegalStateException("core did not open SOCKS5")

            tun = Builder().setSession("ZahraNet").setMtu(8500)
                .addAddress("198.18.0.1", 32).addRoute("0.0.0.0", 0)
                .addDnsServer("1.1.1.1")
                .addDisallowedApplication(packageName) // keep the core's own traffic out of the tunnel
                .establish() ?: throw IllegalStateException("VPN denied")

            val cfg = File(filesDir, "tproxy.yml")
            cfg.writeText("""
tunnel:
  mtu: 8500
  ipv4: 198.18.0.1
socks5:
  port: $socksPort
  address: 127.0.0.1
  udp: 'udp'
misc:
  log-level: warn
""".trimIndent())
            TProxyService.TProxyStartService(cfg.path, tun!!.fd)
            state = "on"
        } catch (e: Exception) {
            stopAll()
        }
    }

    private fun stopAll() {
        try { TProxyService.TProxyStopService() } catch (_: Throwable) {}
        proc?.destroy(); proc = null
        tun?.close(); tun = null
        state = "off"
        stopForeground(STOP_FOREGROUND_REMOVE); stopSelf()
    }

    override fun onRevoke() { stopAll() }
    override fun onDestroy() { stopAll(); super.onDestroy() }

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel("vpn", "VPN", NotificationManager.IMPORTANCE_LOW))
        return Notification.Builder(this, "vpn").setContentTitle("ZahraNet")
            .setContentText("VPN active").setSmallIcon(android.R.drawable.stat_sys_download).build()
    }
}
