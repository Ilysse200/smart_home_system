import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Ensure you have the correct package for light sensor.
import 'package:syncfusion_flutter_charts/charts.dart';

class LightChartScreen extends StatefulWidget {
  @override
  _LightChartScreenState createState() => _LightChartScreenState();
}

class _LightChartScreenState extends State<LightChartScreen> {
  final List<LightData> lightData = [];
  late StreamSubscription<int> _lightSubscription;
  bool _showHighIntensityPopup = true; // Flag for showing high intensity popup
  bool _showLowIntensityPopup = true; // Flag for showing low intensity popup

  @override
  void initState() {
    super.initState();
    _listenToLightSensor();
  }

  void _listenToLightSensor() {
    // Assuming you have a similar package or method to fetch light data
    _lightSubscription = LightSensor.luxStream().listen((int luxValue) {
      final newLightData = LightData(DateTime.now(), luxValue.toDouble());
      setState(() {
        lightData.add(newLightData);
        checkAndTriggerPopups(luxValue.toDouble());
      });
    });
  }

  void checkAndTriggerPopups(double intensity) {
    if (intensity >= 4700 && _showHighIntensityPopup) {
      showAlert('Too much brightness is harmful');
      _showHighIntensityPopup = false;
    } else if (intensity < 4700) {
      _showHighIntensityPopup = true;
    }

    if (intensity < 10 && _showLowIntensityPopup) {
      showAlert('Too little light will harm your sight');
      _showLowIntensityPopup = false;
    } else if (intensity >= 290) {
      _showLowIntensityPopup = true;
    }
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Light Level Alert"),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Intensity Monitor'),
      ),
      body: SfCartesianChart(
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(minimum: 0, maximum: 15000),
        series: <LineSeries<LightData, DateTime>>[
          LineSeries<LightData, DateTime>(
            dataSource: lightData,
            xValueMapper: (LightData data, _) => data.time,
            yValueMapper: (LightData data, _) => data.intensity,
            markerSettings: MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lightSubscription.cancel();
    super.dispose();
  }
}

class LightData {
  LightData(this.time, this.intensity);
  final DateTime time;
  final double intensity;
}
