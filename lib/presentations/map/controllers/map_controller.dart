import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

enum MapMode { normal, selecting }

class MapController extends GetxController {
  final RxnString mapboxToken = RxnString();
  final selectedCoordinates = Rxn<Point>();
  final currentLocation = Rxn<Point>();
  final heading = 0.0.obs;

  var isCompassVisible = false.obs;

  MapboxMap? mapboxMap;
  // Location selection
  var mapMode = MapMode.normal.obs;
  var isAddButtonVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMapboxToken();
    _listenCompass();
    goToCurrentLocation();
  }

  Future<void> _loadMapboxToken() async {
    try {
      const platform = MethodChannel('com.example.app_snapspot/mapbox');
      final token = await platform.invokeMethod<String>('getMapboxToken');

      if (token != null && token.isNotEmpty) {
        MapboxOptions.setAccessToken(token);
        mapboxToken.value = token;
        debugPrint("✅ Token loaded");
      } else {
        debugPrint("⚠️ Token is null or empty");
      }
    } catch (e) {
      debugPrint("❌ Error loading token: $e");
    }
  }

  void onMapCreated(MapboxMap map) {
    mapboxMap = map;
    debugPrint("✅ Mapbox map created");
     
    mapboxMap?.location.updateSettings(LocationComponentSettings(
      enabled: true, 
      pulsingEnabled: true, // hiệu ứng xung nhịp
      puckBearing: PuckBearing.HEADING, // xoay theo hướng
      puckBearingEnabled: true,
  ));
  }

  

  void _listenCompass() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        heading.value = event.heading!;
      }
    });
  }

  Future<void> goToCurrentLocation() async {
    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      final point = Point(
        coordinates: mapbox.Position(position.longitude, position.latitude),
      );

      currentLocation.value = point;
      isCompassVisible.value = true; 

      await mapboxMap?.setCamera(
        CameraOptions(center: point, zoom: 15.0),
      );

    } catch (e) {
      debugPrint("❌ Error getting current location: $e");
    }
  }


  void startLocationSelection() {
    mapMode.value = MapMode.selecting;
    isAddButtonVisible.value = false;
  }

  void cancelLocationSelection() {
    mapMode.value = MapMode.normal;
    isAddButtonVisible.value = true;
  }

  void confirmLocationSelection() async {
    try {
      final cameraState = await mapboxMap?.getCameraState();
      if (cameraState != null) {
        // Lấy center point
        final center = cameraState.center;
        selectedCoordinates.value = center;
        debugPrint(
            "✅ Center coordinates: ${center.coordinates.lat}, ${center.coordinates.lng}");

        // Điều hướng sang CheckinPage
        Get.toNamed('/checkin', arguments: {
          'coordinates': center,
        });

        // Reset UI
        cancelLocationSelection();
      }
    } catch (e) {
      debugPrint("❌ Error getting coordinates: $e");
    }
  }
}
