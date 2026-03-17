import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart'; // 第一週：圓環套件
import 'package:sensors_plus/sensors_plus.dart'; // 第二週：感測器套件
import 'dart:async'; // 第二週：處理監聽流 StreamSubscription

void main() => runApp(const MoveGoApp());

class MoveGoApp extends StatelessWidget {
  const MoveGoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
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
  // --- 【第一部分：變數定義區】 ---
  int _steps = 0; // 步數
  double _calories = 0.0; // 熱量
  double _distance = 0.0; // 距離
  final int _goalSteps = 1000; // 目標步數

  // 第二週新增：感測器訂閱物件
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // --- 【第二部分：核心邏輯區】 ---
  @override
  void initState() {
    super.initState();
    _startTracking(); // App 一啟動就開始聽感測器
  }

  void _startTracking() {
    // 監聽陀螺儀數據
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // 範例：設定每 50 毫秒讀取一次 (約 20Hz)
      gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 50));
      // 核心算法：計算三軸旋轉總和 (取絕對值)
      double motion = event.x.abs() + event.y.abs() + event.z.abs();

      // 設定門檻值為 7.0 (可嘗試修改此數值測試靈敏度)
      if (motion > 7.0) {
        setState(() {
          _steps++;
          _calories = _steps * 0.04; // 換算熱量
          _distance = _steps * 0.0007; // 換算公里
        });
      }
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel(); // 當頁面關閉時，停止聽感測器 (省電)
    super.dispose();
  }

  // --- 【第三部分：介面呈現區】 ---
  @override
  Widget build(BuildContext context) {
    // 計算進度百分比 (0.0 ~ 1.0)
    double percent = (_steps / _goalSteps).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 計步器")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 第一週：圓形進度條
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 15.0,
            percent: percent,
            animation: true,
            animateFromLastPercent: true,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$_steps",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("步"),
              ],
            ),
            progressColor: Colors.orange,
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),

          const SizedBox(height: 50),

          // 第二週新增：數據顯示列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoColumn(
                Icons.local_fire_department,
                _calories.toStringAsFixed(1),
                "kcal",
                Colors.red,
              ),
              _buildInfoColumn(
                Icons.directions_walk,
                _distance.toStringAsFixed(2),
                "km",
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
      // 輔助測試按鈕：手動增加步數 (方便在沒有感測器的環境除錯)
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _steps += 10;
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 自己定義的封裝小工具：建立數據欄位
  Widget _buildInfoColumn(
    IconData icon,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
