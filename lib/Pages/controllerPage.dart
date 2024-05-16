import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ControllerPage extends StatefulWidget {
  static const routeName = '/controller';

  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance.setScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness.instance.resetScreenBrightness();
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to reset brightness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
      ),
      body: Center(
        child: FutureBuilder<double>(
          future: ScreenBrightness.instance.current,
          builder: (context, snapshot) {
            double currentBrightness = 0;
            if (snapshot.hasData) {
              currentBrightness = snapshot.data!;
            }

            return StreamBuilder<double>(
              stream: ScreenBrightness.instance.onCurrentBrightnessChanged,
              builder: (context, snapshot) {
                double changedBrightness = currentBrightness;
                if (snapshot.hasData) {
                  changedBrightness = snapshot.data!;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<bool>(
                      future: ScreenBrightness.instance.hasChanged,
                      builder: (context, snapshot) {
                        return Text(
                            'Brightness has changed via plugin: ${snapshot.data}');
                      },
                    ),
                    Text('Current brightness: $changedBrightness'),
                    Slider.adaptive(
                      value: changedBrightness,
                      onChanged: (value) {
                        setBrightness(value);
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        resetBrightness();
                      },
                      child: const Text('reset brightness'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
