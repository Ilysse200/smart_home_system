import 'package:flutter/material.dart';
import 'package:smart_home_system/Widgets/Screen/pedometer.dart';
import 'package:smart_home_system/Widgets/geofencing.dart';
import 'package:smart_home_system/Widgets/light.dart' as t;
//import 'package:smart_home_system/Widgets/light.dart';
import 'package:smart_home_system/Widgets/light_chart_screen.dart' as l;
import 'package:smart_home_system/Widgets/motionDetector.dart';
import 'package:smart_home_system/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        backgroundColor: Colors.black38, // Deep black color for AppBar
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple, // Deep purple color for Drawer header
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk, color: Colors.black), // Pedometer icon
              title: const Text('Pedometer', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PedometerPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed, color: Colors.black), // Accelerometer icon
              title: const Text('Accelerometer', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MotionDetector()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.black), // Light sensor icon
              title: const Text('Light Sensor App', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => t.BrightnessControl()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Colors.black), // Light graph icon
              title: const Text('Visual Indicators', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => l.LightChartScreen(globalLightData, LightData: null,),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.black), // Google map icon
              title: const Text('Map Icon', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SimpleMap()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[850], // Light dark color for the main page
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_red_eye, // Binoculars-like icon
                color: Colors.white,
                size: 100,
              ),
              SizedBox(height: 20), // Spacing between the icon and the text
              Text(
                'Explore different features',
                style: TextStyle(color: Colors.white), // White text color
              ),
            ],
          ),
        ),
      ),
    );
  }
}
