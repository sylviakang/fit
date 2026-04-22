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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
      ), // 採用文化復古感色系
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

  // --- 【新功能】文化任務資料 ---
  bool _isQuestSolved = false; // 是否已解鎖文化任務
  final String _correctAnswer = "老街"; // 模擬在現場發現的密碼
  final TextEditingController _controller = TextEditingController(); // 捕捉輸入內容

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
      _isQuestSolved = prefs.getBool('questSolved') ?? false;
    });
  }

  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      if (event.x.abs() + event.y.abs() + event.z.abs() > 7.0) {
        setState(() => _steps++);
      }
    });
  }

  // 驗證答案
  void _checkAnswer() async {
    if (_controller.text == _correctAnswer) {
      setState(() {
        _isQuestSolved = true;
        _steps += 500; // 獎勵大量步數
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('questSolved', true);
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("密碼錯誤，請觀察現場環境！")));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("📜 任務達成！"),
        content: const Text("你已成功保護在地文化。獲得獎勵步數 500 步！"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("確定"),
          ),
        ],
      ),
    );
  }

  // --- UI 介面區 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 文化創生"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 原有的計步進度
            CircularPercentIndicator(
              radius: 60,
              lineWidth: 8,
              percent: (_steps / 2000).clamp(0, 1),
              center: Text(
                "$_steps",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: Colors.brown,
            ),

            const Padding(padding: EdgeInsets.all(20), child: Divider()),

            // 【新功能】文化任務卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: _isQuestSolved ? Colors.brown.shade50 : Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.castle, size: 50, color: Colors.brown),
                      const SizedBox(height: 10),
                      const Text(
                        "目前任務：守護文化足跡",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "請前往「當地最古老的地方」，並在此輸入現場公告牌上的紅字密碼。",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      if (!_isQuestSolved) ...[
                        TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "請輸入答案",
                            hintText: "提示：兩位字",
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("提交答案"),
                        ),
                      ] else ...[
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              "已解鎖：在地文化導覽員",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
    _controller.dispose();
    super.dispose();
  }
}
