import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// YOUR REAL RENDER URL - from your screenshot
const String BASE_URL = "https://ambient-host-ea.onrender.com";

void main() => runApp(const PrimeHostApp());

class PrimeHostApp extends StatelessWidget {
  const PrimeHostApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: const Color(0xFF0C0816)),
      home: const BackgroundWrapper(child: MainNav()),
    );
  }
}

// LIVE BACKGROUND LIGHTNING
class BackgroundWrapper extends StatefulWidget {
  final Widget child; const BackgroundWrapper({super.key, required this.child});
  @override State<BackgroundWrapper> createState() => _BackgroundWrapperState();
}
class _BackgroundWrapperState extends State<BackgroundWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState(){ _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); super.initState();}
  @override void dispose(){ _c.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return Stack(children: [
      Container(color: const Color(0xFF0C0816)),
      AnimatedBuilder(animation: _c, builder: (_,__) => CustomPaint(size: Size.infinite, painter: LightningPainter(t: _c.value))),
      Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4, colors: [const Color(0xFF8B5CF6).withOpacity(0.18), Colors.transparent]))),
      widget.child,
    ]);
  }
}
class LightningPainter extends CustomPainter {
  final double t; LightningPainter({required this.t});
  @override void paint(Canvas canvas, Size size){
    final p = Paint()..color = const Color(0xFF8B5CF6).withOpacity(0.06 + 0.08 * sin(t*2*pi))..strokeWidth=1..style=PaintingStyle.stroke;
    final r = Random(1);
    for(int i=0;i<6;i++){ final path=Path(); double x=r.nextDouble()*size.width; double y=-20; path.moveTo(x,y); while(y<size.height){ x+=(r.nextDouble()-0.5)*50; y+=r.nextDouble()*40+20; path.lineTo(x,y);} canvas.drawPath(path,p);}
  }
  @override bool shouldRepaint(covariant LightningPainter old)=>true;
}

class LiveClock extends StatefulWidget { const LiveClock({super.key}); @override State<LiveClock> createState()=>_LiveClockState();}
class _LiveClockState extends State<LiveClock> { late Timer timer; DateTime now=DateTime.now(); @override void initState(){ timer=Timer.periodic(const Duration(seconds:1), (_)=> setState(()=> now=DateTime.now())); super.initState();} @override void dispose(){ timer.cancel(); super.dispose();} @override Widget build(BuildContext context){ return Text("${now.weekday==1?"Mon":now.weekday==2?"Tue":now.weekday==3?"Wed":now.weekday==4?"Thu":now.weekday==5?"Fri":now.weekday==6?"Sat":"Sun"}, ${now.day} ${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][now.month-1]} ${now.year}  ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}", style: const TextStyle(color: Colors.white38, fontSize: 12)); }}

class ApiService {
  static Future<bool> check() async {
    try{ final res= await http.get(Uri.parse("$BASE_URL/")).timeout(const Duration(seconds:10)); return res.statusCode<400; }catch(_){ return false; }
  }
  static Future<Map<String,dynamic>> scan(String pair, String tf) async {
    final res = await http.post(Uri.parse("$BASE_URL/scanner/analyse"), headers: {'Content-Type':'application/json'}, body: jsonEncode({'pair':pair,'timeframe':tf})).timeout(Duration(seconds:20));
    return jsonDecode(res.body);
  }
  static Future addAccount(String login, String pass, String server) async {
    final res = await http.post(Uri.parse("$BASE_URL/mt5/accounts"), headers: {'Content-Type':'application/json'}, body: jsonEncode({'login':login,'password':pass,'server':server,'broker':server}));
    return jsonDecode(res.body);
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override State<MainNav> createState() => _MainNavState();
}
class _MainNavState extends State<MainNav> {
  int idx = 0;
  final screens = [const HomeScreen(), const MetatraderScreen(), const ScannerScreen(), const SettingsScreen()];
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: screens[idx],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF140E26),
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.desktop_windows_outlined), label: "Metatrader"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: "Scanner"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState()=> _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  bool webOk=false; bool loading=true;
  @override void initState(){ super.initState(); ApiService.check().then((v)=> setState((){ webOk=v; loading=false; })); }
  @override Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: LiveClock()),
          const SizedBox(height:6),
          Center(child: Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: webOk ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), border: Border.all(color: webOk ? Colors.green : Colors.red)), child: Text(loading ? "Connecting to $BASE_URL..." : webOk ? "Web CONNECTED • Ambient Live" : "Web OFFLINE • $BASE_URL", style: TextStyle(color: webOk ? Colors.green : Colors.red, fontSize:10)))),
          const SizedBox(height: 12),
          Container(height: 360, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF3A2A60)), gradient: const LinearGradient(colors: [Color(0xFF2A1F45), Color(0xFF0C0816)])), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Icon(Icons.memory, size: 100, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 20),
            const Text("KAYVIEW CHARGER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF8B5CF6)), color: Color(0xFF1E1635)), child: Text(webOk ? "Powered By Ambient • LIVE" : "Powered By Ambient", style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(height: 20),
          ])),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF8B5CF6)), color: const Color(0xFF1A1430)), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Row(children: [Icon(Icons.close, size: 18, color: Color(0xFF8B5CF6)), SizedBox(width: 6), Text("Remove", style: TextStyle(color: Colors.white, fontSize: 13))]),
            Row(children: [Icon(Icons.play_arrow, size: 18, color: Color(0xFF8B5CF6)), SizedBox(width: 6), Text("Start", style: TextStyle(color: Colors.white, fontSize: 13))]),
            Row(children: [Icon(Icons.bar_chart, size: 18, color: Color(0xFF8B5CF6)), SizedBox(width: 6), Text("Symbols", style: TextStyle(color: Colors.white, fontSize: 13))]),
          ])),
          const SizedBox(height: 20),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ROBOT LIST", style: TextStyle(color: Colors.white38, fontSize: 13)), Text("+ Add Key", style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF8B5CF6)), color: const Color(0xFF1A1430)), child: Row(children: [
            const CircleAvatar(backgroundColor: Color(0xFF2A1F45), radius: 22, child: Icon(Icons.memory, color: Colors.white38)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("KAYVIEW CHARGER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text("PHE••••E78", style: TextStyle(color: Colors.white38, fontSize: 11)), Text("Key expires in 361d 15h", style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10))])),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2A1F45), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.delete_outline, size: 18, color: Colors.white38)),
          ])),
        ]),
      ),
    );
  }
}

// ===== METATRADER SCREEN - NOW CONNECTS TO CLOUD =====
class MetatraderScreen extends StatefulWidget {
  const MetatraderScreen({super.key});
  @override State<MetatraderScreen> createState() => _MetatraderScreenState();
}
class _MetatraderScreenState extends State<MetatraderScreen> {
  final loginCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final serverCtrl = TextEditingController(text: "XMGlobal-MT5");
  bool saving = false;
  String msg = "";

  final servers = ["XMGlobal-MT5","XMGlobal-MT5-2","HFM-MT5Real","HFM-MT5Real7","DerivSVG-Server","DerivSVG-Server-02","Exness-MT5Real","Exness-MT5Real2"];

  Future save() async {
    if(loginCtrl.text.isEmpty || passCtrl.text.isEmpty || serverCtrl.text.isEmpty){ setState(()=> msg="All fields required"); return; }
    setState(()=> saving=true);
    try{
      final res = await ApiService.addAccount(loginCtrl.text, passCtrl.text, serverCtrl.text);
      setState(()=> msg = res['success']==true ? "✅ SAVED TO CLOUD: ${res['account']['nickname']}" : "Error: $res");
    }catch(e){ setState(()=> msg="Error: $e"); }
    setState(()=> saving=false);
  }

  @override Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF8B5CF6)), color: const Color(0xFF140E26)), child: const Center(child: Text("MT5 ACCOUNT", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)))),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 8), const Text("CLOUD READY • ANY BROKER", style: TextStyle(color: Colors.white54, fontSize: 12))]),
      const SizedBox(height: 24),
      Container(height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC5A86A)), gradient: const LinearGradient(colors: [Color(0xFF2B2B2B), Color(0xFF0F0F0F)])), child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("KC  KAYVIEW CHARGER • ${serverCtrl.text}", style: TextStyle(color: Color(0xFFC5A86A), fontWeight: FontWeight.bold, fontSize: 14)), Spacer(), Text(msg.isEmpty ? "Supports XMGlobal, HFM, Deriv, Exness" : msg, style: TextStyle(color: Colors.white70, fontSize: 11))]))),
      const SizedBox(height: 20),
      const Align(alignment: Alignment.centerLeft, child: Text("MT5 LOGIN DETAILS", style: TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(height: 16),
      _inputCtrl("Login", loginCtrl),
      const SizedBox(height: 12),
      _inputCtrl("Password", passCtrl, isPass: true),
      const SizedBox(height: 12),
      Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8B5CF6)), color: const Color(0xFF1A1A1A)), child: TextField(controller: serverCtrl, decoration: InputDecoration(hintText: "Server", hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), suffixIcon: PopupMenuButton<String>(icon: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.arrow_drop_down, color: const Color(0xFF8B5CF6))), onSelected: (v)=> setState(()=> serverCtrl.text=v), itemBuilder: (_)=> servers.map((s)=> PopupMenuItem(value:s, child: Text(s, style: TextStyle(fontSize:12)))).toList())))),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: saving?null:save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(saving ? "SAVING TO CLOUD..." : "CONNECT & SAVE TO CLOUD", style: TextStyle(fontWeight: FontWeight.bold)))),
    ])));
  }
  Widget _inputCtrl(String hint, TextEditingController ctrl, {bool isPass=false}) {
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8B5CF6)), color: const Color(0xFF1A1A1A)), child: TextField(controller: ctrl, obscureText: isPass, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16))));
  }
}

// ===== SCANNER SCREEN - NOW EXACTLY LIKE YOUR SCREENSHOT =====
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override State<ScannerScreen> createState() => _ScannerScreenState();
}
class _ScannerScreenState extends State<ScannerScreen> {
  String pair = "XAUUSD";
  String tf = "M15";
  Map<String,dynamic>? data;
  bool loading = true;
  int secAgo = 0;
  late Timer timer;

  @override void initState(){
    super.initState();
    fetchScan();
    timer = Timer.periodic(Duration(seconds:1), (_){ if(mounted) setState(()=> secAgo++); });
  }
  @override void dispose(){ timer.cancel(); super.dispose(); }

  Future fetchScan() async {
    setState(()=> loading=true);
    try{
      final d = await ApiService.scan(pair.contains("XAUUSD") ? "XAUUSD" : pair, tf);
      setState(()=> {data=d, secAgo=0, loading=false});
    }catch(e){
      setState(()=> loading=false);
    }
  }

  @override Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      const SizedBox(height: 6),
      Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6))), child: Center(child: Text(pair[0], style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 10),
      const Text("AI Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Text("SNIPER ELITE · ENTRY HUNTER", style: TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 16),

      // TIMEFRAME SELECTOR LIKE SCREENSHOT
      Align(alignment: Alignment.centerLeft, child: Text("TIMEFRAME", style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1))),
      SizedBox(height: 6),
      Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xFF1E1040), border: Border.all(color: Colors.white12)), child: DropdownButton<String>(value: tf, isExpanded: true, underline: SizedBox(), dropdownColor: Color(0xFF1E1040), items: ["M1","M5","M15","M30","H1","H4"].map((e)=> DropdownMenuItem(value:e, child: Text(e, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))).toList(), onChanged: (v){ setState(()=> tf=v!); fetchScan(); })),

      SizedBox(height: 16),

      // LIVE QUOTE - EXACT LIKE SCREENSHOT
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF121230), border: Border.all(color: Color(0xFF2A2A60))), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("LIVE QUOTE", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)), Text(pair, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]), Text("Updated ${secAgo}s ago", style: TextStyle(color: Colors.white54, fontSize: 11))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Container(padding: EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent), color: Color(0xFF1A0A0A)), child: Column(children: [Text("BID", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text("${data?['bid']?.toString() ?? '46.12769'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))),
          SizedBox(width: 10),
          Expanded(child: Container(padding: EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.greenAccent), color: Color(0xFF0A1A12)), child: Column(children: [Text("ASK", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text("${data?['ask']?.toString() ?? '46.13231'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))),
        ]),
        SizedBox(height: 8),
        Text("SPREAD ${data?['spread'] ?? '0.00461'}", style: TextStyle(color: Colors.white38, fontSize: 11)),
      ])),

      SizedBox(height: 16),

      // LIVE MARKET UPDATE ICT - THE CARD FROM YOUR SCREENSHOT
      if(data != null)
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Color(0xFF121230), border: Border.all(color: Color(0xFF2A2A60))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("LIVE MARKET UPDATE • ICT", style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)), SizedBox(width: 6), Text("$tf • LIVE", style: TextStyle(color: Colors.white54, fontSize: 11))]),
        ]),
        SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("SETUP", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("${data!['setup'] ?? 'Liquidity Sweep + MSS + Order Block Entry'}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("DIRECTION", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("${data!['direction'] ?? 'SELL'}", style: TextStyle(color: (data!['direction']=='SELL') ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16))]),
        ]),
        SizedBox(height: 12),
        Wrap(spacing: 8, children: [Chip(label: Text("HTF bias ${data!['htfBias'] ?? 'bullish'}", style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFF0F1930)), Chip(label: Text("Zone ${data!['zone'] ?? 'premium'}", style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFF0F1930))]),
        SizedBox(height: 12),
        ...List.generate(((data!['details'] as List?) ?? ["BSL liquidity sweep @ 46.045","BOS bullish @ 45.955","Supply OB 45.61-45.67","premium zone (EQ 42.8975)","HTF bias bullish"]).length, (i) => Padding(padding: EdgeInsets.only(bottom: 4), child: Text("▸ ${(data!['details'] as List)[i]}", style: TextStyle(color: Colors.white70, fontSize: 12)))),
        SizedBox(height: 14),
        Row(children: [
          Expanded(child: _smallBox("ENTRY", "${data!['entry'] ?? '46.035'}", "${data!['entryPips'] ?? '950 pips away'}")),
          SizedBox(width: 8),
          Expanded(child: _smallBox("SL", "${data!['sl'] ?? '46.0702'}", "${data!['slPips'] ?? '352 pips'}", color: Colors.redAccent)),
          SizedBox(width: 8),
          Expanded(child: _smallBox("RR (TP1)", "${data!['rr'] ?? '1:1.5'}", "${data!['rrNote'] ?? 'BSL sweep wick 50%'}")),
        ]),
        SizedBox(height: 12),
        _tpRow("TP1", "${data!['tp1'] ?? '45.9822'}", "${data!['tp1Pips'] ?? '1478 pips left'}"),
        SizedBox(height: 8),
        _tpRow("TP2", "${data!['tp2'] ?? '45.947'}", "${data!['tp2Pips'] ?? '1830 pips left'}"),
      ])),

      SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading?null:fetchScan, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B5CF6), padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(loading ? "SCANNING LIVE..." : "⚡ CHARGE LIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),

      SizedBox(height: 10),
      Text("Connected to $BASE_URL", style: TextStyle(color: Colors.white24, fontSize: 10)),
    ])));
  }

  Widget _smallBox(String title, String val, String sub, {Color? color}){
    return Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF0F1930), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(title, style: TextStyle(color: Colors.white54, fontSize: 10)), SizedBox(height: 2), Text(val, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), Text(sub, style: TextStyle(color: Colors.white38, fontSize: 8), textAlign: TextAlign.center)]));
  }
  Widget _tpRow(String label, String val, String sub){
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)), Text("$val  •  $sub", style: TextStyle(color: Colors.white70, fontSize: 12))]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: const [
      Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      SizedBox(height: 12),
      _SetCard(title: "FONT", value: "Space Grotesk"),
      _SetCard(title: "THEME", value: "Purple"),
      _SetCard(title: "BACKGROUND EFFECT", value: "Lightning - LIVE"),
      _SetCard(title: "AI STRATEGY", value: "Auto - Full confluence stack"),
      _SetCard(title: "CLOUD", value: "https://ambient-host-ea.onrender.com • ANY BROKER"),
      _SetCard(title: "AMBIENT HOST EA - VOICE CONTROL", value: "Off"),
    ]));
  }
}
class _SetCard extends StatelessWidget {
  final String title, value; const _SetCard({required this.title, required this.value});
  @override Widget build(BuildContext context) { return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF1E1040), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))])); }
}