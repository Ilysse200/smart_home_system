import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class SettingPage extends StatefulWidget {
  static const routeName = '/setting';

  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isAutoReset = true;
  bool isAnimate = true;

  @override
  void initState() {
    super.initState();
    getIsAutoResetSetting();
    getIsAnimateSetting();
  }

  Future<void> getIsAutoResetSetting() async {
    final isAutoReset = await ScreenBrightness.instance.isAutoReset;
    setState(() {
      this.isAutoReset = isAutoReset;
    });
  }

  Future<void> getIsAnimateSetting() async {
    final isAnimate = await ScreenBrightness.instance.isAnimate;
    setState(() {
      this.isAnimate = isAnimate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Auto Reset'),
            trailing: Switch(
              value: isAutoReset,
              onChanged: (value) async {
                await ScreenBrightness.instance.setAutoReset(value);
                await getIsAutoResetSetting();
              },
            ),
          ),
          ListTile(
            title: const Text('Animate'),
            trailing: Switch(
              value: isAnimate,
              onChanged: (value) async {
                await ScreenBrightness.instance.setAnimate(value);
                await getIsAnimateSetting();
              },
            ),
          )
        ],
      ),
    );
  }
}