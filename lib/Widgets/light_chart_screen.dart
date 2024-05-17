import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

class LightChartScreen extends StatelessWidget {
  final List<LightData> lightData;

  LightChartScreen(this.lightData, {required LightData});

  @override
  Widget build(BuildContext context) {
    double latestIntensity = lightData.isNotEmpty ? lightData.last.intensity : 0;

    Color _getLineColor(double intensity) {
      if (intensity >= 2000.0) {
        return Colors.red;
      } else if (intensity >= 500.0) {
        return Colors.pink;
      } else {
        return Colors.black;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Light Data Chart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 3000),
                series: <CartesianSeries>[
                  LineSeries<LightData, DateTime>(
                    dataSource: lightData,
                    xValueMapper: (LightData data, _) => data.time,
                    yValueMapper: (LightData data, _) => data.intensity,
                    color: _getLineColor(latestIntensity),
                  ),
                ],
              ),
            ),
            if (latestIntensity >= 2000.0)
              _buildAlertBox(context, 'Warning!', 'Too much brightness can be harmful to our eyes.', Icons.warning, Colors.red),
            if (latestIntensity <= 500.0)
              _buildAlertBox(context, 'Warning!', 'Too little light can be harmful to our eyes.', Icons.warning, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBox(BuildContext context, String title, String message, IconData icon, Color iconColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });

    return SizedBox.shrink();
  }
}

class LightData {
  LightData(this.time, this.intensity);
  final DateTime time;
  final double intensity;
}
