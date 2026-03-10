//Week 1
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() => runApp(const StepTrackerApp());

class StepTrackerApp extends StatelessWidget {
  const StepTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My Health Tracker'),
          centerTitle: true,
        ),
        body: const StepCounterPage(),
      ),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  // 測試用的變數
  int currentSteps = 3500;
  int goalSteps = 5000;

  @override
  Widget build(BuildContext context) {
    // 計算百分比 (0.0 ~ 1.0)
    double percent = currentSteps / goalSteps;
    if (percent > 1.0) percent = 1.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 核心功能：圓形進度條
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 15.0,
            animation: true,
            percent: percent,
            center: Text(
              "$currentSteps\n步",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30.0,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.orange,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 30),
          const Text(
            "今日目標：5000 步",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, color: Colors.red, size: 30),
              Text(
                "200 kcal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
