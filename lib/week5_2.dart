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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.lightGreen),
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
  final int _goalSteps = 1000; // 達到此步數則樹木完全長大

  // 【新功能】樹木等級與圖片路徑
  String _treeImage = "assets/seed.png";
  String _treeStatus = "種子階段";

  final List<int> _historySteps = [1500, 2800, 3200, 4500, 1800, 2200, 0];
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTracking();
  }

  // --- 邏輯處理區 ---

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps') ?? 0;
      _updateEverything();
    });
  }

  void _updateEverything() {
    _calories = _steps * 0.04;
    _historySteps[_historySteps.length - 1] = _steps;

    // 【新功能】根據步數判斷樹木成長階段
    if (_steps >= 1000) {
      _treeImage = "assets/tree.png"; // 這裡換成你的圖片路徑
      _treeStatus = "綠意大樹";
    } else if (_steps >= 500) {
      _treeImage = "assets/sapling.png";
      _treeStatus = "茁壯小苗";
    } else {
      _treeImage = "assets/seed.png";
      _treeStatus = "沉睡種子";
    }
  }

  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      double motion = event.x.abs() + event.y.abs() + event.z.abs();
      if (motion > 7.0) {
        setState(() {
          _steps++;
          _updateEverything();
        });
        _saveData();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
  }

  // --- UI 介面區 ---
  @override
  Widget build(BuildContext context) {
    double percent = (_steps / _goalSteps).clamp(0, 1);

    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 虛擬森林"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 【新功能】樹木視覺化顯示
            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade100, width: 4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 圓形進度條在外圈
                  // CircularPercentIndicator(
                  //   radius: 60,
                  //   lineWidth: 4,
                  //   percent: percent,
                  //   progressColor: Colors.green,
                  //   backgroundColor: Colors.transparent,
                  //   circularStrokeCap: CircularStrokeCap.round,
                  // ),
                  // 樹木圖片在中心
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 如果沒有圖片，可以用 Emoji 代替測試： Text(_treeImage == "assets/tree.png" ? "🌳" : "🌱", style: TextStyle(fontSize: 80)),
                      Image.asset(
                        _treeImage,
                        height: 72,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.eco,
                          size: 72,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _treeStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text("今日已行走 $_steps 步", style: const TextStyle(fontSize: 18)),

            const Divider(height: 40, indent: 30, endIndent: 30),

            // 第四週：圖表
            const Text(
              "運動對環境的貢獻",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildChart(),

            const SizedBox(height: 20),

            // 數據卡片
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoTile(
                  Icons.local_fire_department,
                  _calories.toStringAsFixed(1),
                  "kcal",
                ),
                _buildInfoTile(
                  Icons.park,
                  (_steps / 1000).toStringAsFixed(1),
                  "棵樹",
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _steps += 100;
            _updateEverything();
          });
          _saveData();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_reaction, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: BarChart(
        BarChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _historySteps.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: Colors.green.withOpacity(e.key == 6 ? 1.0 : 0.3),
                  width: 14,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
