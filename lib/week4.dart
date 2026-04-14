import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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
  // --- 資料定義區 ---
  int _steps = 0;
  double _calories = 0.0;
  bool _badge1 = false;
  bool _badge2 = false;
  bool _badge3 = false;

  // 歷史數據清單：最後一項 [_historySteps[6]] 代表今天
  final List<int> _historySteps = [150, 280, 320, 450, 180, 220, 0];

  // 第二週核心：感測器訂閱
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _loadData(); // 第三週：讀取存檔
    _startTracking(); // 第二週：啟動感測器
  }

  // --- 邏輯處理區 ---

  // 讀取存檔
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps') ?? 0;
      _badge1 = prefs.getBool('badge1') ?? false;
      _badge2 = prefs.getBool('badge2') ?? false;
      _badge3 = prefs.getBool('badge3') ?? false;
      _updateEverything();
    });
  }

  // 統一更新所有狀態 (步數、卡路里、勳章、圖表)
  void _updateEverything() {
    _calories = _steps * 0.04;
    // 檢查勳章門檻
    if (_steps >= 10 && !_badge1) _badge1 = true;
    if (_steps >= 50 && !_badge2) _badge2 = true;
    if (_steps >= 100 && !_badge3) _badge3 = true;
    // 更新圖表：今日步數同步到 List 的最後一項
    _historySteps[_historySteps.length - 1] = _steps;
  }

  // 第二週功能回歸：陀螺儀監聽
  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      // 計算三軸旋轉總量
      double motion = event.x.abs() + event.y.abs() + event.z.abs();

      // 若晃動門檻 > 7.0 則判定為一步
      if (motion > 7.0) {
        setState(() {
          _steps++;
          _updateEverything();
        });
        _saveData(); // 第三週：存檔功能
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
    await prefs.setBool('badge1', _badge1);
    await prefs.setBool('badge2', _badge2);
    await prefs.setBool('badge3', _badge3);
  }

  // --- UI 介面區 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 終極運動日誌"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 第一週：圓形進度
            CircularPercentIndicator(
              radius: 80,
              lineWidth: 10,
              percent: (_steps / 500).clamp(0, 1),
              center: Text(
                "$_steps\nSteps",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              progressColor: Colors.blue,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            ),
            const SizedBox(height: 15),
            Text(
              "燃燒熱量: ${_calories.toStringAsFixed(1)} kcal",
              style: const TextStyle(color: Colors.grey),
            ),

            const Divider(height: 40, indent: 30, endIndent: 30),

            // 第四週：趨勢圖表
            const Text(
              "一週運動趨勢",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildChart(),

            const SizedBox(height: 20),

            // 第三週：勳章牆
            const Text(
              "成就獎勵",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge("👟", "千步之行", _badge1),
                const SizedBox(width: 40),
                _buildBadge("🔥", "燃脂達人", _badge2),
                const SizedBox(width: 40),
                _buildBadge("🏆", "運動達人", _badge3),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // 輔助測試按鈕
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _steps += 10;
            _updateEverything();
          });
          _saveData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _historySteps.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: e.key == 6
                      ? Colors.blue
                      : Colors.blue.withOpacity(0.2),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBadge(String icon, String label, bool isUnlocked) {
    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isUnlocked ? 1.0 : 0.2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
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
