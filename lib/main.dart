import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
  // --- 數據變數 ---
  int _steps = 0;
  double _calories = 0.0;
  double _distance = 0.0;
  final int _goalSteps = 1000; // 預設目標 1000 步

  // 歷史數據清單：前 6 天為模擬數據，最後一項為今日
  final List<int> _historySteps = [1200, 3000, 2500, 4500, 3800, 2000, 0];

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // 鷹架重點：先讀取舊有數據，再開始監聽新動作
    _loadStoredData().then((_) {
      _startTracking();
    });
  }

  // --- 1. 核心邏輯：讀取資料 ---
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 確保讀取到資料，若為 null 則給 0
      _steps = prefs.getInt('steps') ?? 0;
      _updateEverything(); // 重要：讀取完後立即更新計算與圖表
    });
  }

  // --- 2. 核心邏輯：更新所有相關數據 ---
  void _updateEverything() {
    _calories = _steps * 0.04;
    _distance = _steps * 0.0007; // 1步約 0.7 公尺 = 0.0007 公里

    // 更新圖表：將今日步數同步到歷史清單的最後一位
    _historySteps[_historySteps.length - 1] = _steps;
  }

  // --- 3. 核心邏輯：感測器與儲存 ---
  void _startTracking() {
    _subscription = gyroscopeEventStream().listen((event) {
      // 計算三軸旋轉總量
      double motion = event.x.abs() + event.y.abs() + event.z.abs();

      // 門檻值 7.0 可依模擬器靈敏度調整
      if (motion > 7.0) {
        setState(() {
          _steps++;
          _updateEverything();
        });
        _saveData(); // 即時存檔，確保重啟不遺失
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
  }

  // 重置功能：教學測試用
  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _steps = 0;
      _updateEverything();
    });
  }

  @override
  Widget build(BuildContext context) {
    double percent = (_steps / _goalSteps).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MoveGo 健康追蹤"),
        actions: [IconButton(onPressed: _resetData, icon: Icon(Icons.refresh))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 數據環形卡片
            _buildStatusCard(percent),
            const SizedBox(height: 20),
            // 趨勢圖表區
            _buildChartSection(),
            const SizedBox(height: 20),
            // 勳章系統
            _buildBadgeSection(),
          ],
        ),
      ),
      // 輔助功能：點擊按鈕手動增加 10 步，方便測試
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _steps += 10;
            _updateEverything();
          });
          _saveData();
        },
        child: const Icon(Icons.directions_run),
      ),
    );
  }

  // --- UI 組件：狀態卡片 ---
  Widget _buildStatusCard(double percent) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularPercentIndicator(
              radius: 65,
              lineWidth: 12,
              percent: percent,
              animation: true,
              animateFromLastPercent: true,
              center: Text(
                "$_steps\nSteps",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile(
                  Icons.local_fire_department,
                  "${_calories.toStringAsFixed(1)} kcal",
                  Colors.orange,
                ),
                const SizedBox(height: 10),
                _infoTile(
                  Icons.add_location_alt,
                  "${_distance.toStringAsFixed(2)} km",
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI 組件：圖表區 ---
  Widget _buildChartSection() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(show: false), // 簡化 UI，隱藏座標軸文字
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _historySteps[i].toDouble(),
                  color: i == 6 ? Colors.blue : Colors.blue.withOpacity(0.3),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI 組件：勳章區 ---
  Widget _buildBadgeSection() {
    return Column(
      children: [
        const Text(
          "成就獎勵",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badgeIcon("👟", "千步之行", _steps >= 1000),
            const SizedBox(width: 20),
            _badgeIcon("🔥", "燃脂達人", _calories >= 40),
            const SizedBox(width: 20),
            _badgeIcon("🏆", "今日滿分", _steps >= _goalSteps),
          ],
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _badgeIcon(String emoji, String label, bool unlocked) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: unlocked ? 1.0 : 0.15,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// 簡易版本如下
// import 'package:flutter/material.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'dart:async';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// void main() => runApp(const StepTrackerApp());

// class StepTrackerApp extends StatelessWidget {
//   const StepTrackerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
//       home: const StepCounterPage(),
//     );
//   }
// }

// class StepCounterPage extends StatefulWidget {
//   const StepCounterPage({super.key});

//   @override
//   State<StepCounterPage> createState() => _StepCounterPageState();
// }

// class _StepCounterPageState extends State<StepCounterPage> {
//   int currentSteps = 0;
//   double calories = 0.0; // 新增：卡路里變數
//   int goalSteps = 100;

//   bool hasBadge1 = false;
//   bool hasBadge2 = false;
//   bool hasBadge3 = false;

//   StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _startListening();
//   }

//   // 讀取存檔
//   Future<void> _loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       currentSteps = prefs.getInt('steps') ?? 0;
//       // 從步數回推卡路里，或者也可以直接存 calories 變數
//       calories = currentSteps * 0.04;
//       hasBadge1 = prefs.getBool('badge1') ?? false;
//       hasBadge2 = prefs.getBool('badge2') ?? false;
//       hasBadge3 = prefs.getBool('badge3') ?? false;
//     });
//   }

//   // 儲存存檔
//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('steps', currentSteps);
//     await prefs.setBool('badge1', hasBadge1);
//     await prefs.setBool('badge2', hasBadge2);
//     await prefs.setBool('badge3', hasBadge3);
//   }

//   void _startListening() {
//     _gyroscopeSubscription = gyroscopeEventStream().listen((
//       GyroscopeEvent event,
//     ) {
//       double totalRotation = event.x.abs() + event.y.abs() + event.z.abs();
//       if (totalRotation > 5.0) {
//         setState(() {
//           currentSteps++;
//           calories = currentSteps * 0.04; // 步數轉卡路里公式
//           _checkBadges();
//           _saveData();
//         });
//       }
//     });
//   }

//   void _checkBadges() {
//     if (currentSteps >= 10 && !hasBadge1) {
//       hasBadge1 = true;
//       _showBadgeDialog("👟 初試啼聲", "恭喜！你已經踏出了第一步！");
//     }
//     if (currentSteps >= 50 && !hasBadge2) {
//       hasBadge2 = true;
//       _showBadgeDialog("🔥 持續邁進", "燃燒吧，卡路里！");
//     }
//     if (currentSteps >= 100 && !hasBadge3) {
//       hasBadge3 = true;
//       _showBadgeDialog("🏆 運動達人", "今天也是充滿活力的一天！");
//     }
//   }

//   void _showBadgeDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("太棒了"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     double percent = (currentSteps / goalSteps).clamp(0.0, 1.0);

//     return Scaffold(
//       appBar: AppBar(title: const Text('卡路里計步器'), centerTitle: true),
//       body: Column(
//         children: [
//           const SizedBox(height: 40),
//           // 圓圈進度
//           CircularPercentIndicator(
//             radius: 110.0,
//             lineWidth: 15.0,
//             percent: percent,
//             center: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "$currentSteps",
//                   style: const TextStyle(
//                     fontSize: 40,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Text("Steps"),
//               ],
//             ),
//             progressColor: Colors.deepOrange,
//             backgroundColor: Colors.grey.shade200,
//             circularStrokeCap: CircularStrokeCap.round,
//           ),

//           const SizedBox(height: 30),

//           // --- 新增：卡路里與進度資訊卡 ---
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildInfoStat(
//                 Icons.local_fire_department,
//                 "${calories.toStringAsFixed(1)}",
//                 "kcal",
//                 Colors.red,
//               ),
//               _buildInfoStat(Icons.flag, "$goalSteps", "目標", Colors.blue),
//             ],
//           ),

//           const Spacer(),

//           // 成就徽章區
//           const Text(
//             "成就徽章",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildBadgeItem("👟", "10步", hasBadge1, Colors.orange),
//               _buildBadgeItem("🔥", "50步", hasBadge2, Colors.red),
//               _buildBadgeItem("🏆", "100步", hasBadge3, Colors.amber),
//             ],
//           ),
//           const SizedBox(height: 50),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoStat(IconData icon, String value, String unit, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 30),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         Text(unit, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildBadgeItem(
//     String icon,
//     String label,
//     bool isUnlocked,
//     Color activeColor,
//   ) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 30,
//           backgroundColor: isUnlocked ? activeColor : Colors.grey.shade300,
//           child: Text(icon, style: const TextStyle(fontSize: 25)),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: isUnlocked ? Colors.black : Colors.grey,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }
// }
