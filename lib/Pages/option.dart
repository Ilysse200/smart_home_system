import 'package:flutter/material.dart';
import 'package:smart_home_system/Pages/blankPage.dart';
import 'package:smart_home_system/Pages/controllerPage.dart';
import 'package:smart_home_system/Pages/homePage.dart';
import 'package:smart_home_system/Pages/routeAware.dart';
import 'package:smart_home_system/Pages/settingPage.dart';

class Option extends StatelessWidget {
  static final RouteObserver<Route> routeObserver = RouteObserver<Route>();

  const Option({super.key});

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
