import 'dart:async';
import 'package:app_snapspot/core/common_widgets/custom_detail_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_location_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_marker_helper.dart';
import 'package:app_snapspot/core/common_widgets/custom_point_annotation_click_listener.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/data/models/spot_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  mapbox.PointAnnotationManager? _annotationManager;

  /// cache icon marker theo category để không phải render lại nhiều lần
  final Map<String, Uint8List> _markerCache = {};
  final Map<String, PointAnnotation> _markerCacheById = {};

  /// mapping annotationId -> checkInId
  final Map<String, String> _annotationIdToCheckInId = {};

  var mapMode = MapMode.normal.obs;
  var isAddButtonVisible = true.obs;
  var isBottomSheetOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMapboxToken();
    _initLocation();
  }

  void _initLocation() {
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

  void onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    debugPrint("✅ Mapbox map created");

    mapboxMap?.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      puckBearing: PuckBearing.HEADING,
      puckBearingEnabled: true,
    ));

    // Tạo annotation manager 1 lần, dùng lại khi tạo marker
    _annotationManager =
        await mapboxMap!.annotations.createPointAnnotationManager();

    // Gắn custom listener
    // ignore: deprecated_member_use
    _annotationManager?.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
        annotationIdToSpotId: _annotationIdToCheckInId,
        onMarkerTapped: onMarkerTapped,
      ),
    );

    goToCurrentLocation();

    // Nếu có checkin mới trả về từ màn checkin thì add marker đó
    final args = Get.arguments;
    if (args != null && args is SpotModel) {
      addSpotMarker(args);
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
        // ignore: deprecated_member_use
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

        final result = await Get.toNamed('/checkin', arguments: {
          'coordinates': center,
        });

        if (result != null && result is SpotModel) {
          addSpotMarker(result);
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

  /// Thêm marker mới ngay sau khi checkin thành công
  Future<void> addSpotMarker(SpotModel spot) async {
    if (mapboxMap == null) return;

    if (_markerCacheById.containsKey(spot.id)) {
      debugPrint("⚠️ Marker ${spot.id} đã tồn tại trong cache, bỏ qua");
      return;
    }

    if (spot.categoryIcon.isEmpty) return;

    final markerBytes = await getMarkerIcon(spot.categoryIcon);

    final annotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(spot.longitude, spot.latitude),
        ),
        image: markerBytes,
        iconSize: 1.0,
      ),
    );

    _markerCacheById[spot.id] = annotation;
    _annotationIdToCheckInId[annotation.id] = spot.id;
  }

  // Lắng nghe sự kiện camera thay đổi
  void onCameraChanged(CameraChangedEventData eventData) async {
    try {
      final cameraState = await mapboxMap?.getCameraState();
      if (cameraState == null) return;

      final bounds = await mapboxMap?.coordinateBoundsForCamera(
        cameraState.toCameraOptions(),
      );

      if (bounds != null) {
        await loadMarkersInView(bounds);
      }
    } catch (e) {
      debugPrint("❌ Error in onCameraChanged: $e");
    }
  }

  /// Load marker theo view camera
  Future<void> loadMarkersInView(CoordinateBounds bounds) async {
    if (mapboxMap == null) return;

    try {
      final spotRepo = SpotRepository();

      // Lấy Spot theo bounding box
      final spots = await spotRepo.getSpotsInBoundingBox(
        minLat: bounds.southwest.coordinates.lat.toDouble(),
        maxLat: bounds.northeast.coordinates.lat.toDouble(),
        minLng: bounds.southwest.coordinates.lng.toDouble(),
        maxLng: bounds.northeast.coordinates.lng.toDouble(),
      );

      int newCount = 0;

      for (final spot in spots) {
        final id = spot.id;
        if (_markerCacheById.containsKey(id)) {
          continue; // đã có marker
        }

        final markerBytes = await getMarkerIcon(spot.categoryIcon);
        final annotation = await _annotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(spot.longitude, spot.latitude),
            ),
            image: markerBytes,
            iconSize: 1.0,
          ),
        );

        _markerCacheById[id] = annotation;
        _annotationIdToCheckInId[annotation.id] = id; // lưu spotId
        newCount++;
      }

      debugPrint(
          "✅ Loaded $newCount new spot markers (cache size=${_markerCacheById.length})");
    } catch (e) {
      debugPrint("❌ Error loading spot markers in view: $e");
    }
  }

  /// Khi user tap vào marker Spot
  Future<void> onMarkerTapped(String spotId) async {
    if (isBottomSheetOpen.value) return;
    isBottomSheetOpen.value = true;

    try {
      final spotDoc = await FirebaseFirestore.instance
          .collection("spots")
          .doc(spotId)
          .get();

      if (!spotDoc.exists) {
        isBottomSheetOpen.value = false;
        return;
      }

      final spot = SpotModel.fromJson(spotDoc.data()!..['id'] = spotDoc.id);

      await Get.bottomSheet(
        LocationCheckInsBottomSheet(spot: spot),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      debugPrint("❌ Error loading spot: $e");
    } finally {
      isBottomSheetOpen.value = false;
    }
  }
}
