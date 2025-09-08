import 'dart:async';
import 'package:app_snapspot/core/common_widgets/custom_marker_helper.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// cache icon marker theo category để không phải render lại nhiều lần
  final Map<String, Uint8List> _markerCache = {};

  // Location selection
  var mapMode = MapMode.normal.obs;
  var isAddButtonVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMapboxToken();
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
      pulsingEnabled: true,
      puckBearing: PuckBearing.HEADING,
      puckBearingEnabled: true,
    ));

    goToCurrentLocation();

    // Load tất cả markers khi map được tạo
    loadMarkers();

    // Nếu có checkin mới trả về từ màn checkin thì add marker đó
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      addCheckInMarker(args);
    }
  }

  Future<void> goToCurrentLocation() async {
    try {
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
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
        CameraOptions(center: point, zoom: 16.0),
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
        final center = cameraState.center;
        selectedCoordinates.value = center;
        debugPrint(
            "✅ Center coordinates: ${center.coordinates.lat}, ${center.coordinates.lng}");

        // chuyển sang màn checkin
        final result = await Get.toNamed('/checkin', arguments: {
          'coordinates': center,
        });

        // nếu checkin thành công, thêm marker mới vào map
        if (result != null && result is Map<String, dynamic>) {
          addCheckInMarker(result);
        }

        cancelLocationSelection();
      }
    } catch (e) {
      debugPrint("❌ Error getting coordinates: $e");
    }
  }

  /// Lấy icon marker có cache
  Future<Uint8List> getMarkerIcon(String icon) async {
    if (_markerCache.containsKey(icon)) {
      return _markerCache[icon]!;
    }
    final markerBytes = await CustomMarkerHelper.createGoogleStyleMarker(
      icon,
      size: 160,
    );
    _markerCache[icon] = markerBytes;
    return markerBytes;
  }

  /// Load toàn bộ markers từ Firestore
  Future<void> loadMarkers() async {
    if (mapboxMap == null) return;
    try {
      final checkinRepo = CheckInRepository();
      final checkIns = await checkinRepo.getMarkerData();

      final manager = await mapboxMap!.annotations.createPointAnnotationManager();

      final annotationFutures = checkIns.map((checkIn) async {
        final markerBytes = await getMarkerIcon(checkIn['categoryIcon']);
        return PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              checkIn['longitude'],
              checkIn['latitude'],
            ),
          ),
          image: markerBytes,
          iconSize: 1.0,
        );
      }).toList();

      final annotations = await Future.wait(annotationFutures);
      await manager.createMulti(annotations);

      debugPrint("✅ Loaded ${annotations.length} markers");
    } catch (e) {
      debugPrint("❌ Error loading markers: $e");
    }
  }

  /// Thêm marker mới ngay sau khi checkin thành công
  Future<void> addCheckInMarker(Map<String, dynamic> checkIn) async {
    if (mapboxMap == null) return;

    final lat = checkIn['latitude'] as double;
    final lng = checkIn['longitude'] as double;
    final iconUrl = checkIn['categoryIcon'] as String?;

    if (iconUrl == null || iconUrl.isEmpty) return;

    final markerBytes = await getMarkerIcon(iconUrl);

    final manager = await mapboxMap!.annotations.createPointAnnotationManager();

    await manager.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)),
      image: markerBytes,
      iconSize: 1.0,
    ));

    debugPrint("✅ Added new marker: $lat, $lng");
  }
}
