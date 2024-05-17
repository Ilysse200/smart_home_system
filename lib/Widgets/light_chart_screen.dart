import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

class LightChartScreen extends StatefulWidget {
  final List<LightData> lightData;

  LightChartScreen(this.lightData);

  @override
  _LightChartScreenState createState() => _LightChartScreenState();
}

class _LightChartScreenState extends State<LightChartScreen> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Data Chart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 5000),
                tooltipBehavior: _tooltipBehavior,
                series: <CartesianSeries>[
                  LineSeries<LightData, DateTime>(
                    dataSource: widget.lightData.isNotEmpty ? widget.lightData : [LightData(DateTime.now(), 0)],
                    xValueMapper: (LightData data, _) => data.time,
                    yValueMapper: (LightData data, _) => data.intensity,
                    color: widget.lightData.isNotEmpty ? getColorForValue(widget.lightData.last.intensity) : Colors.black,
                    width: 2,
                    markerSettings: MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getColorForValue(double intensity) {
    if (intensity > 4000) {
      return Colors.red; // High intensity
    } else if (intensity > 1000) {
      return Colors.orange; // Moderate intensity
    } else {
      return Colors.green; // Low intensity
    }
  }
}

class LightData {
  LightData(this.time, this.intensity);
  final DateTime time;
  final double intensity;
}
