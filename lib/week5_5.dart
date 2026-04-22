import 'package:flutter/material.dart';
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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
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
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // --- 【新功能】地圖資料 ---
  // 模擬景點資料：名稱、位置(x, y)、是否為低碳標章
  final List<Map<String, dynamic>> _ecoSpots = [
    {"name": "綠色餐廳 A", "x": 50.0, "y": 100.0, "type": "Food"},
    {"name": "永續旅宿 B", "x": 150.0, "y": 50.0, "type": "Hotel"},
    {"name": "低碳公園 C", "x": 250.0, "y": 120.0, "type": "Park"},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTracking();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _steps = prefs.getInt('steps') ?? 0);
  }

  void _startTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      if (event.x.abs() + event.y.abs() + event.z.abs() > 7.0) {
        setState(() => _steps++);
      }
    });
  }

  // --- UI 介面區 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoveGo 低碳導覽地圖"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 計步資訊
            Text("今日已累計步數：$_steps 步", style: const TextStyle(fontSize: 16)),

            const Padding(padding: EdgeInsets.all(10), child: Divider()),

            // 【新功能】地圖區標題
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Text(
                    "附近永續景點",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 【新功能】模擬地圖畫布
            Container(
              margin: const EdgeInsets.all(20),
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueGrey.shade100, width: 2),
              ),
              child: Stack(
                children: [
                  // 背景裝飾格線
                  const GridPaper(
                    color: Colors.blueGrey,
                    interval: 50,
                    divisions: 1,
                    subdivisions: 1,
                  ),

                  // 使用 .map 遍歷產生景點標記 (Markers)
                  ..._ecoSpots.map(
                    (spot) => Positioned(
                      left: spot['x'],
                      top: spot['y'],
                      child: GestureDetector(
                        onTap: () => _showSpotInfo(spot['name'], spot['type']),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 30,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              color: Colors.white70,
                              child: Text(
                                spot['name'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "💡 點擊地圖上的綠色標記查看詳情",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpotInfo(String name, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "類別：$type",
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 5),
            const Text("此地點符合 SDG 11 永續城鄉指標，提供低碳餐點或環保住宿。"),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(child: Text("關閉")),
            ),
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
