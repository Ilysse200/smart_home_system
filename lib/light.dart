import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:smart_home_system/main.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

class BrightnessControl extends StatefulWidget {
  const BrightnessControl({super.key});
  @override
  _BrightnessControlState createState() => _BrightnessControlState();
}

class _BrightnessControlState extends State<BrightnessControl> {
  double _lightLevel = 0.0;
  bool _showHighIntensityPopup = true;
  bool _showLowIntensityPopup = true;
  late StreamSubscription<int> _lightSubscription;
  List<LightData> _lightData = [];

  @override
  void initState() {
    super.initState();
    _listenToLightSensor();
  }

  void _listenToLightSensor() {
    LightSensor.hasSensor().then((hasSensor) {
      if (hasSensor) {
        _lightSubscription = LightSensor.luxStream().listen((int luxValue) {
          setState(() {
            _lightLevel = luxValue.toDouble();
            _lightData.add(LightData(DateTime.now(), _lightLevel));
            if (_lightData.length > 100) {
              _lightData.removeAt(0);
            }
            checkAndTriggerPopups();
          });
        });
      } else {
        return;
      }
    });
  }

  void checkAndTriggerPopups() {
    if (_lightLevel >= 2000.0 && _showHighIntensityPopup) {
      _showNotification('Light Intensity', 'High ambient light levels.');
      _showAlertDialog('Warning!', 'Too much brightness can be harmful to our eyes.', Icons.warning, Colors.red);
      _showHighIntensityPopup = false;
    } else if (_lightLevel < 2000.0) {
      _showHighIntensityPopup = true;
    }

    if (_lightLevel <= 500.0 && _showLowIntensityPopup) {
      _showNotification('Light Intensity', 'Low ambient light levels.');
      _showAlertDialog('Warning!', 'Too little light can be harmful to our eyes.', Icons.warning, Colors.blue);
      _showLowIntensityPopup = false;
    } else if (_lightLevel > 500.0) {
      _showLowIntensityPopup = true;
    }
  }

  Color _getLineColor(double intensity) {
    if (intensity >= 2000.0) {
      return Colors.red;
    } else if (intensity >= 500.0) {
      return Colors.pink;
    } else {
      return Colors.black;
    }
  }

  void _showAlertDialog(String title, String message, IconData icon, Color iconColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Sensor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Light Level: ${_lightLevel.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 3000),
                series: <CartesianSeries>[
                  LineSeries<LightData, DateTime>(
                    dataSource: _lightData,
                    xValueMapper: (LightData data, _) => data.time,
                    yValueMapper: (LightData data, _) => data.intensity,
                    color: _getLineColor(_lightLevel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotification(String header, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'LightSensor_channel',
      'Light Sensor Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      header,
      body,
      platformChannelSpecifics,
    );
  }
}

class LightData {
  LightData(this.time, this.intensity);
  final DateTime time;
  final double intensity;
}
