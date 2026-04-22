import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() => runApp(const MoveGoApp());

class MoveGoApp extends StatelessWidget {
  const MoveGoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
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
  // --- 基礎資料 ---
  int _steps = 0;

  // --- 【新功能】減塑挑戰資料 ---
  // 定義三個挑戰項目：自備餐具、不買瓶裝水、使用環保袋
  final List<bool> _ecoChecks = [false, false, false];
  final List<String> _challengeTitles = ["自備環保餐具", "拒買瓶裝水", "自備購物袋"];
  final List<IconData> _challengeIcons = [
    Icons.restaurant,
    Icons.water_drop,
    Icons.shopping_bag,
  ];

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
      // 讀取布林值清單，若無資料則預設為 false
      _ecoChecks[0] = prefs.getBool('eco0') ?? false;
      _ecoChecks[1] = prefs.getBool('eco1') ?? false;
      _ecoChecks[2] = prefs.getBool('eco2') ?? false;
    });
  }

  Future<void> _saveEcoData(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eco$index', value);
  }

  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      double motion = event.x.abs() + event.y.abs() + event.z.abs();
      if (motion > 7.0) {
        setState(() {
          _steps++;
        });
        // 為了效能，此處建議使用先前討論過的批次存檔，此處簡化處理
      }
    });
  }

  // --- UI 介面區 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 減塑挑戰"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 原有的計步進度
            CircularPercentIndicator(
              radius: 70,
              lineWidth: 8,
              percent: (_steps / 1000).clamp(0, 1),
              center: Text("$_steps\n步", textAlign: TextAlign.center),
              progressColor: Colors.teal,
            ),

            const Padding(padding: EdgeInsets.all(20.0), child: Divider()),

            // 【新功能】減塑清單標題
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.teal),
                  SizedBox(width: 10),
                  Text(
                    "今日減塑任務",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 【新功能】動態產生 Checkbox 列表
            ListView.builder(
              shrinkWrap: true, // 重要：在 Column 中使用 ListView 必須設為 true
              physics:
                  const NeverScrollableScrollPhysics(), // 由外層 SingleChildScrollView 處理滾動
              itemCount: _challengeTitles.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _ecoChecks[index]
                        ? Colors.teal.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CheckboxListTile(
                    title: Text(_challengeTitles[index]),
                    secondary: Icon(
                      _challengeIcons[index],
                      color: _ecoChecks[index] ? Colors.teal : Colors.grey,
                    ),
                    value: _ecoChecks[index],
                    activeColor: Colors.teal,
                    onChanged: (bool? value) {
                      setState(() {
                        _ecoChecks[index] = value!;
                        // 當勾選任務時，給予 100 步的鼓勵獎勵！
                        if (value) _steps += 100;
                      });
                      _saveEcoData(index, value!);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 任務統計提示
            Text(
              "已完成 ${_ecoChecks.where((c) => c).length} / 3 項任務",
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }
}
