import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MotionDetector extends StatefulWidget {
  @override
  _MotionDetectorState createState() => _MotionDetectorState();
}

class _MotionDetectorState extends State<MotionDetector> {
  double? x, y, z;
  bool isShaking = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];
  Duration sensorInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    // Subscribe to accelerometer events
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (AccelerometerEvent event) {
          setState(() {
            x = event.x;
            y = event.y;
            z = event.z;
            // Determine if the device is shaking
            bool currentlyShaking = x!.abs() > 10 || y!.abs() > 10 || z!.abs() > 10;
            if (currentlyShaking && !isShaking) {
              isShaking = true;
              showShakeDialog(); // Show dialog on shake
            } else if (!currentlyShaking) {
              isShaking = false;
            }
          });
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Sensor Error"),
                content: Text("Error accessing the accelerometer: $e"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
  }

  void showShakeDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Motion Detected"),
          content: Text("Shaking has been detected."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel(); // Cancel all subscriptions
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Motion Detector'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('X-axis: ${x?.toStringAsFixed(2)}'),
            Text('Y-axis: ${y?.toStringAsFixed(2)}'),
            Text('Z-axis: ${z?.toStringAsFixed(2)}'),
            if (isShaking) Text('Shaking detected!', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
