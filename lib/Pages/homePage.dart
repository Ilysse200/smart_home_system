import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:smart_home_system/Pages/blankPage.dart';
import 'package:smart_home_system/Pages/controllerPage.dart';
import 'package:smart_home_system/Pages/routeAware.dart';
import 'package:smart_home_system/Pages/settingPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final RouteObserver<Route> routeObserver = RouteObserver<Route>();

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      onGenerateRoute: (settings) {
        late final Widget page;
        switch (settings.name) {
          case HomePage.routeName:
            page = const HomePage();
            break;

          case ControllerPage.routeName:
            page = const ControllerPage();
            break;

          case RouteAwarePage.routeName:
            page = const RouteAwarePage();
            break;

          case BlankPage.routeName:
            page = const BlankPage();
            break;

          case SettingPage.routeName:
            page = const SettingPage();
            break;

          default:
            throw UnimplementedError('page name not found');
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
      navigatorObservers: [
        routeObserver,
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  static const routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen brightness example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<double>(
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

                    return Text('current brightness $changedBrightness');
                  },
                );
              },
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(ControllerPage.routeName),
              child: const Text('Controller example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteAwarePage.routeName),
              child: const Text('Route aware example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SettingPage.routeName),
              child: const Text('Setting page'),
            ),
          ],
        ),
      ),
    );
  }
}