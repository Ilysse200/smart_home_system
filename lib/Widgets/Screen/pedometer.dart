import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PedometerPage extends StatefulWidget {
  const PedometerPage({super.key});

  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  bool isPaused = false;
  double stepThreshold = 12.0;
  double stepSensitivity = 2.0;
  double previousMagnitude = 0.0;
  double lastStepTime = 0.0;
  int stepCount = 0;
  double caloriesBurned = 0.0;
  double calorieGoal = 50.0;
  late StreamSubscription<AccelerometerEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEvents.listen((event) {
      if (!isPaused) {
        updateStepCount(event);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void updateStepCount(AccelerometerEvent event) {
    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (magnitude > previousMagnitude + stepSensitivity && magnitude > stepThreshold && (currentTime - lastStepTime) > 500) {
      setState(() {
        stepCount++;
        caloriesBurned += 0.04;
        lastStepTime = currentTime;
      });
    }
    previousMagnitude = magnitude;
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Pedometer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(Icons.directions_walk, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text('Steps: $stepCount', style: const TextStyle(fontSize: 24)),
            Text('Calories burned: ${caloriesBurned.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24)),
            Text('Goal: $calorieGoal Calories', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (caloriesBurned >= calorieGoal)
              const Text('Goal Reached!', style: TextStyle(fontSize: 24, color: Colors.green)),
            ElevatedButton(
              onPressed: togglePause,
              child: Text(isPaused ? 'Resume' : 'Pause'),
            ),
          ],
        ),
      ),
    );
  }
}