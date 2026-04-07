import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 第三週新增
import 'dart:async';

void main() => runApp(const MoveGoApp());

class MoveGoApp extends StatelessWidget {
  const MoveGoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MoveGoHomePage(),
    );
  }
}

class MoveGoHomePage extends StatefulWidget {
  const MoveGoHomePage({super.key});
  @override
  State<MoveGoHomePage> createState() => _MoveGoHomePageState();
}

class _MoveGoHomePageState extends State<MoveGoHomePage> {
  int _steps = 0;
  final int _goalSteps = 100; // 測試用門檻設低一點

  // 第三週新增：勳章解鎖狀態
  bool _badge1 = false; // 10步
  bool _badge2 = false; // 50步

  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _loadData(); // 第一件事：讀取舊存檔
    _startTracking();
  }

  // --- 【第三週核心：存取邏輯】 ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps') ?? 0;
      _badge1 = prefs.getBool('badge1') ?? false;
      _badge2 = prefs.getBool('badge2') ?? false;
      _updateStats();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
    await prefs.setBool('badge1', _badge1);
    await prefs.setBool('badge2', _badge2);
  }

  void _updateStats() {
    // 檢查勳章邏輯
    if (_steps >= 10 && !_badge1) _badge1 = true;
    if (_steps >= 50 && !_badge2) _badge2 = true;
  }

  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      double motion = event.x.abs() + event.y.abs() + event.z.abs();
      if (motion > 7.0) {
        setState(() {
          _steps++;
          _updateStats();
        });
        _saveData(); // 每次移動都存檔
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double percent = (_steps / _goalSteps).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 記憶與成就")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 100,
              lineWidth: 12,
              percent: percent,
              center: Text("$_steps\nSteps", textAlign: TextAlign.center),
              progressColor: Colors.blue,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 40),
            // 第三週新增：勳章列
            const Text("成就解鎖", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge("👟", "初試啼聲", _badge1),
                const SizedBox(width: 20),
                _buildBadge("🔥", "燃脂新手", _badge2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String icon, String label, bool isUnlocked) {
    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(seconds: 1),
          opacity: isUnlocked ? 1.0 : 0.2, // 未解鎖則變淡
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 30)),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }
}
