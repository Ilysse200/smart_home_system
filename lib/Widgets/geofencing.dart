import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_home_system/Widgets/constant.dart';

class SimpleMap extends StatefulWidget {
  const SimpleMap({super.key});

  @override
  State<SimpleMap> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  final LatLng destinationLocation = LatLng(-1.9501, 30.0589); // Example coordinates for KK 561 St
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);

  Location _locationController = Location();
  Map<PolygonId, Polygon> _polygons = {};
  Map<PolylineId, Polyline> polylines = {};

  Set<Marker> _markers = {}; // Initialize an empty set of markers
  LatLng? currentLocation; // Assuming you have a way to get the current location
  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  bool _notificationSentOutSide = false;
  bool _notificationSentInSide = false;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    getCurrentLocation();
    _createGeofence();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void getCurrentLocation() async {
    var result = await location.getLocation();
    if (result != null && result.latitude != null && result.longitude != null) {
      setState(() {
        currentLocation = LatLng(result.latitude ?? 0 , result.longitude ?? 0);
        addCurrentLocMarker(currentLocation);
      });
    }

    _locationSubscription = location.onLocationChanged.listen((LocationData newLoc) {
      if (newLoc.latitude != null && newLoc.longitude != null) {
        setState(() {
          currentLocation = LatLng(newLoc.latitude ?? 0, newLoc.longitude ?? 0);
          addCurrentLocMarker(currentLocation);
          _checkGeofenceStatus(newLoc.latitude ?? 0, newLoc.longitude ?? 0);
        });
      }
    });
  }

  void addCurrentLocMarker(LatLng? location) {
    if (location != null) {
      Marker currentLocMarker = Marker(
        markerId: MarkerId('currentLocation'),
        icon: BitmapDescriptor.defaultMarker,
        position: location,
        infoWindow: InfoWindow(title: 'Current Location', snippet: 'You are here'),
      );
      setState(() {
        _markers.add(currentLocMarker);
      });
    }
  }

  void _createGeofence() {
    // Define the boundaries for the five-sided geofence
    List<LatLng> fenceBounds = [
      LatLng(-1.9740, 30.0274), // Northwest corner
      LatLng(-1.9740, 30.1300), // Northeast corner
      LatLng(-1.8980, 30.1300), // Southeast corner
      LatLng(-1.9120, 30.0787), // Southwest point (custom)
      LatLng(-1.9480, 30.0500), // Center west point (custom)
    ];

    // Create a polygon to represent the geofence boundaries
    PolygonId polygonId = PolygonId('fiveSidedFence');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: fenceBounds,
      strokeWidth: 2,
      strokeColor: Color.fromARGB(236, 142, 129, 218).withOpacity(0.3),
      fillColor: Color.fromARGB(27, 136, 98, 130).withOpacity(0.3),
    );

    setState(() {
      _polygons[polygonId] = polygon;
    });
  }

  void _checkGeofenceStatus(double latitude, double longitude) {
    bool insideGeofence = _isLocationInsideGeofence(latitude, longitude);

    if (insideGeofence && !_notificationSentInSide) {
      _triggerInSideNotification();
      _notificationSentInSide = true;
      _notificationSentOutSide = false;
    } else if (!insideGeofence && !_notificationSentOutSide) {
      _triggerOutSideNotification();
      _notificationSentOutSide = true;
      _notificationSentInSide = false;
    }
  }

  bool _isLocationInsideGeofence(double latitude, double longitude) {
    // Check if the provided location is inside the geofence boundaries
    bool isInside = false;
    List<LatLng> fenceBoundaries = [
      LatLng(-1.9740, 30.0274),
      LatLng(-1.9740, 30.1300),
      LatLng(-1.8980, 30.0274),
    ];

    // Algorithm to determine if a point is inside a polygon
    int i, j = fenceBoundaries.length - 1;
    for (i = 0; i < fenceBoundaries.length; i++) {
      if ((fenceBoundaries[i].latitude < latitude &&
                  fenceBoundaries[j].latitude >= latitude ||
              fenceBoundaries[j].latitude < latitude &&
                  fenceBoundaries[i].latitude >= latitude) &&
          (fenceBoundaries[i].longitude <= longitude ||
              fenceBoundaries[j].longitude <= longitude)) {
        if (fenceBoundaries[i].longitude +
                (latitude - fenceBoundaries[i].latitude) /
                    (fenceBoundaries[j].latitude -
                        fenceBoundaries[i].latitude) *
                    (fenceBoundaries[j].longitude -
                        fenceBoundaries[i].longitude) <
            longitude) {
          isInside = !isInside;
        }
      }
      j = i;
    }
    return isInside;
  }

  Future<void> _triggerInSideNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geo_fence_channel',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Inside Geofence',
      'You are inside the geofence area.',
      platformChannelSpecifics,
    );
  }

  Future<void> _triggerOutSideNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geo_fence_channel',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Outside Geofence',
      'You are outside the geofence area.',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simple Google Map"),
        centerTitle: true,
      ),
      body: GoogleMap(
        onMapCreated: ((GoogleMapController controller) => _controller.complete(controller)),
        initialCameraPosition: CameraPosition(target: destinationLocation, zoom: 13),
        polygons: Set<Polygon>.of(_polygons.values),
        markers: _markers,
        polylines: Set<Polyline>.of(polylines.values),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
