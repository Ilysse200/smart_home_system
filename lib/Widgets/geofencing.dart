import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geo_fencing_demo/constant.dart';
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

  static const LatLng _pGooglePlex=LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark=LatLng(37.3346, -122.0090);

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
    getPolylinePoints().then((coordinates) => {
              generatePolyLineFromPoints(coordinates),
    });
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
    currentLocation = await location.getLocation().then((value) {
      currentLocation = LatLng(value.latitude!, value.longitude!);
      addCurrentLocMarker(currentLocation!);
      return currentLocation;
    });

    _locationSubscription = location.onLocationChanged.listen((newLoc) {
      setState(() {
        currentLocation = LatLng(newLoc.latitude!, newLoc.longitude!);
        addCurrentLocMarker(currentLocation!);
        _checkGeofenceStatus(newLoc.latitude!, newLoc.longitude!);
      });
    });
  }

  void _createGeofence() {
    // Define the boundaries for the larger geofence around Kigali
    List<LatLng> fenceBounds = [
      LatLng(-1.9740, 30.0274), // Northwest corner
      LatLng(-1.9740, 30.1300), // Northeast corner
      LatLng(-1.8980, 30.1300), // Southeast corner
    ];

    // Create a polygon to represent the geofence boundaries
    PolygonId polygonId = PolygonId('myFence');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: fenceBounds,
      strokeWidth: 2,
      strokeColor: Color.fromARGB(255, 179, 0, 0),
      fillColor: Color.fromARGB(237, 245, 110, 110).withOpacity(0.3),
    );

    // Add the polygon to the map
    setState(() {
      _polygons[polygonId] = polygon;
    });

    // Start location updates subscription to monitor device's location
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      // Check if the device's location is inside or outside the geofence
      bool insideGeofence = _isLocationInsideGeofence(
          currentLocation.latitude!, currentLocation.longitude!);

      if (insideGeofence && !_notificationSentInSide) {
        _triggerInSideNotification();
        _notificationSentInSide = true;
        _notificationSentOutSide = false;
      } else if (!insideGeofence && !_notificationSentOutSide) {
        _triggerOutSideNotification();
        _notificationSentOutSide = true;
        _notificationSentInSide = false;
   }});}

  void addCurrentLocMarker(LatLng location) {
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

  void addDestinationMarker() {
    Marker destinationMarker = Marker(
      markerId: MarkerId('destinationLocation'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      position: destinationLocation,
      infoWindow: InfoWindow(title: 'Destination Location', snippet: 'Destination location...'),
    );
    setState(() {
      _markers.add(destinationMarker);
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // PI / 180
    final double a = 0.5 - 
        cos((lat2 - lat1) * p) / 2 + 
        cos(lat1 * p) * cos(lat2 * p) * 
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
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
    print('Inside geofence notification sent');
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
    print('Outside geofence notification sent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simple Google Map"),
        centerTitle: true,
      ),
      body: GoogleMap(
              onMapCreated: ((GoogleMapController controller) =>
                  _controller.complete(controller)),
              initialCameraPosition: CameraPosition(
                target: destinationLocation,
                zoom: 13,
              ),
              polygons: Set<Polygon>.of(_polygons.values),
              markers: {
                Marker(
                  markerId: MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: currentLocation!,
                ),
                Marker(
                    markerId: MarkerId("_sourceLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _pGooglePlex),
                Marker(
                    markerId: MarkerId("_destionationLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _pApplePark)
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
      PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
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

}
