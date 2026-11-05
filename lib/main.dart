import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ch = MethodChannel('zahranet/vpn');
const bg = Color(0xFF0A0420), card = Color(0xFF1A0F3D), line = Color(0xFF2E1D66);
const violet = Color(0xFF7B2FFF), violet2 = Color(0xFFA855F7), green = Color(0xFF22D68A), red = Color(0xFFFF4D6D);
const gold = Color(0xFFFFC857), dim = Color(0xFF9B8EC9);

class Method {
  final String name, fa, flag, cmd;
  const Method(this.name, this.fa, this.flag, this.cmd);
}
const methods = [
  Method('MASQUE', 'سریع و پایدار (پیشنهادی)', '⚡', '--masque'),
  Method('Gool', 'مسیر Warp-in-Warp', '🌐', '--gool'),
  Method('Psiphon', 'سایفون', '🛡️', '--psiphon'),
  Method('Tor', 'تور (کندتر، ناشناس‌تر)', '🧅', '--tor'),
];

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ariana VPN',
        theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: bg),
        builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
        home: const Splash(),
      );
}

BoxDecoration glass([Color? border]) => BoxDecoration(
    color: card.withOpacity(.85), borderRadius: BorderRadius.circular(18),
    border: Border.all(color: border ?? line));

// ---------------- Splash ----------------
class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}
class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
    });
  }
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.3), radius: 1.1, colors: [Color(0xFF3B1590), bg])),
          child: SafeArea(
            child: Column(children: [
              const Spacer(flex: 2),
              const Text('👑', style: TextStyle(fontSize: 44)),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: violet2.withOpacity(.6), blurRadius: 80)]),
                child: const Icon(Icons.shield, size: 120, color: violet2),
              ),
              const SizedBox(height: 18),
              const Text('ARIANA VPN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const Text('آریانا وی‌پی‌ان', style: TextStyle(fontSize: 22)),
              const Spacer(),
              const Text('آزادانه در اینترنت بچرخید…', style: TextStyle(fontSize: 16)),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 14, 40, 0),
                child: AnimatedBuilder(animation: a, builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: a.value, minHeight: 6, color: violet2, backgroundColor: line))),
              ),
              const Spacer(),
              const Text('طراحی و توسعه:', style: TextStyle(color: dim)),
              const Text('فاطمه زهرا ساعی', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      );
}

// ---------------- Shell + state ----------------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int tab = 0;
  Method sel = methods[0];
  String state = 'off';
  bool irancell = true;
  String err = '';
  int secs = 0, tx = 0, rx = 0;
  Timer? t;

  @override
  void initState() {
    super.initState();
    _sim();
    t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }
  @override
  void dispose() { t?.cancel(); super.dispose(); }

  Future<void> _sim() async {
    final v = await ch.invokeMethod<bool>('isIrancell') ?? false;
    if (mounted) setState(() => irancell = v);
  }
  Future<void> _tick() async {
    final s = await ch.invokeMethod<String>('status') ?? 'off';
    if (s == 'on') {
      final st = (await ch.invokeMethod<List>('stats'))?.cast<int>() ?? [0, 0, 0, 0];
      if (mounted) setState(() { state = s; secs++; tx = st[1]; rx = st[3]; });
    } else if (mounted) {
      setState(() { state = s; secs = 0; });
    }
  }
  Future<void> toggle() async {
    if (state != 'off') { await ch.invokeMethod('stop'); return; }
    await _sim();
    if (!irancell) return;
    if (!(await ch.invokeMethod<bool>('prepare') ?? false)) { setState(() => err = 'مجوز VPN داده نشد'); return; }
    setState(() { err = ''; state = 'connecting'; });
    await ch.invokeMethod('start', {'mode': sel.cmd});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Home(s: this),
      Servers(s: this, onDone: () => setState(() => tab = 0)),
      About(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF12082E), indicatorColor: violet.withOpacity(.35),
        selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.dns_outlined), selectedIcon: Icon(Icons.dns), label: 'روش اتصال'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'درباره'),
        ],
      ),
    );
  }
}

// ---------------- Home ----------------
String fmtBytes(int b) => b < 1048576 ? '${(b / 1024).toStringAsFixed(1)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';
String fmtTime(int s) => '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

class Home extends StatelessWidget {
  final _ShellState s;
  const Home({super.key, required this.s});
  @override
  Widget build(BuildContext context) {
    final on = s.state == 'on', busy = s.state == 'connecting';
    final col = !s.irancell ? red : on ? green : violet;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Text('👑', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Text('ARIANA VPN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16), decoration: glass(),
        child: Row(children: [
          const Text('🇮🇷', style: TextStyle(fontSize: 34)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('وضعیت اتصال:', style: TextStyle(color: dim)),
            Text(!s.irancell ? 'فقط ایرانسل' : on ? 'متصل است' : busy ? 'در حال اتصال…' : 'قطع است',
                style: TextStyle(color: on ? green : busy ? gold : red, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
      const SizedBox(height: 28),
      Center(
        child: GestureDetector(
          onTap: (busy || !s.irancell) ? null : s.toggle,
          child: Container(
            width: 190, height: 190,
            decoration: BoxDecoration(shape: BoxShape.circle, color: col.withOpacity(.25),
                boxShadow: [BoxShadow(color: col.withOpacity(.55), blurRadius: 60)]),
            child: Center(
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: col, border: Border.all(color: Colors.white24, width: 4)),
                child: busy
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Icon(on ? Icons.check_rounded : Icons.power_settings_new, size: 72, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(child: Text(!s.irancell ? 'این برنامه فقط روی سیم‌کارت ایرانسل کار می‌کند'
          : on ? fmtTime(s.secs) : 'برای اتصال کلیک کنید',
          style: TextStyle(fontSize: on ? 24 : 16, fontWeight: FontWeight.w600))),
      if (s.err.isNotEmpty) Center(child: Text(s.err, style: const TextStyle(color: red))),
      const SizedBox(height: 18),
      if (on)
        Row(children: [
          Expanded(child: _stat('دریافت', fmtBytes(s.rx), Icons.arrow_downward, green)),
          const SizedBox(width: 10),
          Expanded(child: _stat('ارسال', fmtBytes(s.tx), Icons.arrow_upward, violet2)),
        ]),
      const SizedBox(height: 14),
      InkWell(
        onTap: s.state == 'off' ? () => s.setState(() => s.tab = 1) : null,
        child: Container(
          padding: const EdgeInsets.all(16), decoration: glass(),
          child: Row(children: [
            const Icon(Icons.public, color: dim),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('روش اتصال', style: TextStyle(color: dim, fontSize: 12)),
              Text('${s.sel.flag} ${s.sel.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ])),
            const Icon(Icons.chevron_left, color: dim),
          ]),
        ),
      ),
    ]);
  }
  Widget _stat(String l, String v, IconData i, Color c) => Container(
        padding: const EdgeInsets.all(14), decoration: glass(),
        child: Row(children: [
          Icon(i, color: c), const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: const TextStyle(color: dim, fontSize: 12)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ]),
      );
}

// ---------------- Servers (connection methods) ----------------
class Servers extends StatelessWidget {
  final _ShellState s;
  final VoidCallback onDone;
  const Servers({super.key, required this.s, required this.onDone});
  @override
  Widget build(BuildContext context) => Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerRight,
            child: Text('انتخاب روش اتصال', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final m in methods)
            GestureDetector(
              onTap: s.state == 'off' ? () => s.setState(() => s.sel = m) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                decoration: glass(s.sel == m ? violet2 : null),
                child: Row(children: [
                  Text(m.flag, style: const TextStyle(fontSize: 26)), const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(m.fa, style: const TextStyle(color: dim, fontSize: 12)),
                  ])),
                  Icon(s.sel == m ? Icons.radio_button_checked : Icons.radio_button_off, color: violet2),
                ]),
              ),
            ),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 52,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: violet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: onDone, child: const Text('تأیید انتخاب', style: TextStyle(fontSize: 16))))),
      ]);
}

// ---------------- About ----------------
class About extends StatelessWidget {
  About({super.key});
  final items = const [
    (Icons.bolt, 'سرعت بالا', gold), (Icons.verified_user, 'امن و مطمئن', violet2),
    (Icons.sim_card, 'سازگار با سیم‌کارت ایرانسل', green),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        for (final i in items)
          Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: glass(),
              child: Row(children: [Icon(i.$1, color: i.$3, size: 28), const SizedBox(width: 14),
                Text(i.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))])),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(20), decoration: glass(violet2),
          child: Column(children: const [
            Text('ARIANA VPN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: violet2)),
            SizedBox(height: 8),
            Text('طراحی و توسعه توسط', style: TextStyle(color: dim)),
            Text('💜 فاطمه زهرا ساعی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Text('هسته اتصال: Aether (CluvexStudio) · AGPL-3.0', style: TextStyle(color: dim, fontSize: 11)),
          ])),
      ]);
}
