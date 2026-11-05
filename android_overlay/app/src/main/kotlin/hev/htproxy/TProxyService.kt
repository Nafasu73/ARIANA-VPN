package hev.htproxy

// JNI bridge of hev-socks5-tunnel (libhev-socks5-tunnel.so). Verify the class/method
// names against the version of the library you build.
object TProxyService {
    init { System.loadLibrary("hev-socks5-tunnel") }
    @JvmStatic external fun TProxyStartService(configPath: String, fd: Int)
    @JvmStatic external fun TProxyStopService()
    @JvmStatic external fun TProxyGetStats(): LongArray // [txPackets, txBytes, rxPackets, rxBytes]
}
