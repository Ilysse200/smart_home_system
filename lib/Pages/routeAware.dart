import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:smart_home_system/Pages/blankPage.dart';
import 'package:smart_home_system/Pages/option.dart';
import 'package:smart_home_system/main.dart';

class RouteAwarePage extends StatefulWidget {
  static const routeName = '/routeAware';

  const RouteAwarePage({super.key});

  @override
  State<RouteAwarePage> createState() => _RouteAwarePageState();
}

class _RouteAwarePageState extends State<RouteAwarePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Option.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    super.didPush();
    ScreenBrightness.instance.setScreenBrightness(0.7);
  }

  @override
  void didPushNext() {
    super.didPushNext();
    ScreenBrightness.instance.resetScreenBrightness();
  }

  @override
  void didPop() {
    super.didPop();
    ScreenBrightness.instance.resetScreenBrightness();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    ScreenBrightness.instance.setScreenBrightness(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route aware'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(BlankPage.routeName),
          child: const Text('Next page'),
        ),
      ),
    );
  }
}