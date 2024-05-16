import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:smart_home_system/Widgets/constant.dart';
import 'package:smart_home_system/main.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Location _locationService = Location();
  final Completer<GoogleMapController> _googleMapController = Completer<GoogleMapController>();
  LatLng _centralKigali = LatLng(-1.9441, 30.0619); // Coordinates for Kigali center
  static const LatLng _googlePlex = LatLng(37.4223, -122.0848);
  static const LatLng _applePark = LatLng(37.3346, -122.0090);
  LatLng? _currentPosition;
  Map<PolylineId, Polyline> _routePolylines = {};
  Circle? _geofenceCircle;
  StreamSubscription<LocationData>? _locationStreamSubscription;
  bool _insideGeofenceNotificationSent = false;
  bool _outsideGeofenceNotificationSent = false;

  @override
  void initState() {
    super.initState();
    initializeLocationUpdates().then(
      (_) => {
        retrievePolylineCoordinates().then((points) => {
              createPolylineFromCoordinates(points),
            }),
      },
    );
    setupGeofence();
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel(); // Cancel location updates subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Your Location',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
      ),
      body: _currentPosition == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: ((GoogleMapController controller) =>
                  _googleMapController.complete(controller)),
              initialCameraPosition: CameraPosition(
                target: _centralKigali,
                zoom: 13,
              ),
              circles: _geofenceCircle != null ? {_geofenceCircle!} : {},
              markers: {
                Marker(
                  markerId: MarkerId("_currentPosition"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _currentPosition!,
                ),
                Marker(
                    markerId: MarkerId("_startLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _googlePlex),
                Marker(
                    markerId: MarkerId("_endLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _applePark)
              },
              polylines: Set<Polyline>.of(_routePolylines.values),
            ),
    );
  }

  void sendInsideGeofenceNotification() async {
    if (!_insideGeofenceNotificationSent) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Geofence_channel', // Change this to match your channel ID
        'Geofence Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Hello!',
        'Inside Geographical Boundaries of Kigali',
        platformChannelSpecifics,
      );
      print('Inside geofence notification sent');
      _insideGeofenceNotificationSent = true;
      _outsideGeofenceNotificationSent = false;
    }
  }

  void sendOutsideGeofenceNotification() async {
    if (!_outsideGeofenceNotificationSent) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Geofence_channel', // Change this to match your channel ID
        'Geofence Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Hello!',
        'Outside Geographical Boundaries of Kigali',
        platformChannelSpecifics,
      );
      print('Outside geofence notification sent');
      _outsideGeofenceNotificationSent = true;
      _insideGeofenceNotificationSent = false;
    }
  }

  void setupGeofence() {
    // Define the center and radius for the circular geofence around Kigali
    LatLng geofenceCenter = _centralKigali;
    double geofenceRadius = 5000; // in meters

    // Create a circle to represent the geofence boundaries
    Circle geofence = Circle(
      circleId: CircleId('kigali_geofence'),
      center: geofenceCenter,
      radius: geofenceRadius,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
    );

    // Add the circle to the map
    setState(() {
      _geofenceCircle = geofence;
    });

    // Start location updates subscription to monitor device's location
    startLocationUpdates();
  }

  void startLocationUpdates() async {
    _locationStreamSubscription = _locationService.onLocationChanged
        .listen((LocationData currentLocation) {
      // Check if the device's location is inside or outside the geofence
      bool insideGeofence = isInsideGeofence(
          currentLocation.latitude!, currentLocation.longitude!);

      if (insideGeofence && !_insideGeofenceNotificationSent) {
        sendInsideGeofenceNotification();
        _insideGeofenceNotificationSent = true;
        _outsideGeofenceNotificationSent = false;
      } else if (!insideGeofence && !_outsideGeofenceNotificationSent) {
        sendOutsideGeofenceNotification();
        _outsideGeofenceNotificationSent = true;
        _insideGeofenceNotificationSent = false;
      }
    });
  }

  bool isInsideGeofence(double latitude, double longitude) {
    // Check if the provided location is inside the geofence boundaries
    final distance = _calculateDistance(
        latitude, longitude, _centralKigali.latitude, _centralKigali.longitude);
    return distance <= _geofenceCircle!.radius;
  }

 double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static double cos(num x) {
    return Math.cos(x);
  }

  Future<void> _moveCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _googleMapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: position,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> initializeLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationStreamSubscription = _locationService.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        LatLng newLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // Update the marker to the new location
        updateLocationMarker(newLocation);

        // Optionally, keep track of the path by adding to your polyline
        addLocationToRoutePolyline(newLocation);

        _moveCameraToPosition(newLocation);
      }
    });
  }

  void updateLocationMarker(LatLng newLocation) {
    setState(() {
      _currentPosition = newLocation;
      // Update your marker or create a new one if needed
    });
  }

  void addLocationToRoutePolyline(LatLng newLocation) {
    setState(() {
      // Check if polyline exists, if not create one
      if (_routePolylines.containsKey(PolylineId("path"))) {
        final polyline = _routePolylines[PolylineId("path")]!;
        final updatedPoints = List<LatLng>.from(polyline.points)
          ..add(newLocation);
        _routePolylines[PolylineId("path")] =
            polyline.copyWith(pointsParam: updatedPoints);
      } else {
        // Create new polyline if it doesn't exist
        _routePolylines[PolylineId("path")] = Polyline(
          polylineId: PolylineId("path"),
          color: Colors.blue,
          points: [newLocation],
          width: 5,
        );
      }
    });
  }

  Future<List<LatLng>> retrievePolylineCoordinates() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(_googlePlex.latitude, _googlePlex.longitude),
      PointLatLng(_applePark.latitude, _applePark.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void createPolylineFromCoordinates(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("polyline");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      _routePolylines[id] = polyline;
    });
  }
}
