import 'dart:async';
import 'package:app_snapspot/core/common_widgets/custom_location_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_marker_helper.dart';
import 'package:app_snapspot/core/common_widgets/custom_point_annotation_click_listener.dart';
import 'package:app_snapspot/data/models/spot_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Cache markers
  final Map<String, Uint8List> _markerCache = {};
  final Map<String, PointAnnotation> _markerCacheById = {};
  final Map<String, String> _annotationIdToSpotId = {};

  var mapMode = MapMode.normal.obs;
  var isAddButtonVisible = true.obs;
  var isBottomSheetOpen = false.obs;

  /// Filter/Search
  var selectedCategory = Rxn<String>();
  var searchQuery = "".obs;
  var isLoading = false.obs;

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
      }
    } catch (e) {
      debugPrint("❌ Error loading token: $e");
    }
  }

  void onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    debugPrint("✅ Map created");

    mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        puckBearingEnabled: true,
      ),
    );

    _annotationManager =
        await mapboxMap!.annotations.createPointAnnotationManager();

    _annotationManager?.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
        annotationIdToSpotId: _annotationIdToSpotId,
        onMarkerTapped: onMarkerTapped,
      ),
    );

    goToCurrentLocation();

    // nếu có spot từ màn checkin trả về
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
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      final point = Point(
        coordinates: mapbox.Position(position.longitude, position.latitude),
      );

      currentLocation.value = point;
      isCompassVisible.value = true;

      await mapboxMap?.setCamera(
        CameraOptions(center: point, zoom: 17.0),
      );
    } catch (e) {
      debugPrint("❌ Error getting current location: $e");
    }
  }

  // Selection Mode
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

  // Marker utils
  Future<Uint8List> getMarkerIcon(String icon) async {
    if (_markerCache.containsKey(icon)) return _markerCache[icon]!;
    final markerBytes =
        await CustomMarkerHelper.createGoogleStyleMarker(icon, size: 160);
    _markerCache[icon] = markerBytes;
    return markerBytes;
  }

  Future<void> addSpotMarker(SpotModel spot) async {
    if (mapboxMap == null) return;
    if (_markerCacheById.containsKey(spot.id)) return;
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
    _annotationIdToSpotId[annotation.id] = spot.id;
  }

  // Filter + Search
  void updateCategory(String? category) {
    selectedCategory.value = category;
    reloadSpotsInView();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    reloadSpotsInView();
  }

  // Loading Spots by Bounding Box
  void onCameraChanged(CameraChangedEventData eventData) async {
    // Chỉ load khi có filter hoặc search
    if (selectedCategory.value != null || searchQuery.value.isNotEmpty) {
      final cameraState = await mapboxMap?.getCameraState();
      if (cameraState == null) return;

      final bounds = await mapboxMap?.coordinateBoundsForCamera(
        cameraState.toCameraOptions(),
      );
      if (bounds != null) {
        await loadMarkersInView(bounds);
      }
    }
  }

  Future<void> reloadSpotsInView() async {
    final cameraState = await mapboxMap?.getCameraState();
    if (cameraState == null) return;

    final bounds = await mapboxMap?.coordinateBoundsForCamera(
      cameraState.toCameraOptions(),
    );
    if (bounds != null) {
      // Xóa toàn bộ marker cũ trước khi load lại
      await clearAllMarkers();

      await loadMarkersInView(bounds);
    }
  }

  Future<void> clearAllMarkers() async {
    if (_annotationManager == null) return;

    // Xóa annotations khỏi map
    await _annotationManager!.deleteAll();

    // Clear cache
    _markerCacheById.clear();
    _annotationIdToSpotId.clear();
  }

  Future<void> loadMarkersInView(CoordinateBounds bounds) async {
    if (mapboxMap == null) return;
    isLoading.value = true;

    try {
      final spotRepo = SpotRepository();
      final spots = await spotRepo.getSpotsInBoundingBoxFiltered(
        minLat: bounds.southwest.coordinates.lat.toDouble(),
        maxLat: bounds.northeast.coordinates.lat.toDouble(),
        minLng: bounds.southwest.coordinates.lng.toDouble(),
        maxLng: bounds.northeast.coordinates.lng.toDouble(),
        category: selectedCategory.value,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      int newCount = 0;
      for (final spot in spots) {
        if (_markerCacheById.containsKey(spot.id)) continue;
        await addSpotMarker(spot);
        newCount++;
      }

      debugPrint(
          "✅ Loaded $newCount new markers (cache=${_markerCacheById.length})");
    } catch (e) {
      debugPrint("❌ Error loading markers: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================
  // Marker click
  // ==========================
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
      final user = FirebaseAuth.instance.currentUser;
      final currentUserId = user?.uid;

      await Get.bottomSheet(
        Builder(
          builder: (_) {
            Get.put<LocationCheckInsController>(
              LocationCheckInsController(
                CheckInRepository(),
                spot.id,
                currentUserId!,
              ),
              tag: spot.id,
            );
            return LocationCheckInsBottomSheet(
              spot: spot,
              currentUserId: currentUserId!,
            );
          },
        ),
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
