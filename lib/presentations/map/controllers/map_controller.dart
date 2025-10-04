import 'dart:async';
import 'package:app_snapspot/applications/services/mapbox_service.dart';
import 'package:app_snapspot/core/common_widgets/custom_location_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_marker_helper.dart';
import 'package:app_snapspot/core/common_widgets/custom_point_annotation_click_listener.dart';
import 'package:app_snapspot/data/models/spot_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/search_filter_controller.dart';
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

  PolylineAnnotationManager? _polylineManager;
  final List<PolylineAnnotation> _polylineAnnotations = [];

  var mapMode = MapMode.normal.obs;
  var isAddButtonVisible = true.obs;
  var isBottomSheetOpen = false.obs;

  /// Filter/Search
  var selectedCategory = Rxn<String>();
  var searchQuery = "".obs;
  var isLoading = false.obs;

  /// Route
  var routeDistance = 0.0.obs;
  var hasActiveRoute = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMapboxToken();
    _initLocation();

    final filterCtrl = Get.find<SearchFilterController>();
    ever(filterCtrl.selectedCategoryId, (String? catId) {
      selectedCategory.value = catId;
      reloadSpotsInView();
    });
    ever(filterCtrl.searchQuery, (String query) {
      searchQuery.value = query;
      reloadSpotsInView();
    });
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
      debugPrint("Error loading token: $e");
    }
  }

  void onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    debugPrint("✅ Map created");

    await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/satellite-v9");

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

  Future<geo.Position?> goToCurrentLocation() async {
    try {
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return null;
      }
      if (permission == geo.LocationPermission.deniedForever) return null;

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

      return position;
    } catch (e) {
      debugPrint("Error getting current location: $e");
      return null;
    }
  }

  Future<void> _clearRoute() async {
    try {
      if (_polylineManager != null) {
        // Xóa tất cả annotations do polyline manager quản lý
        await _polylineManager!.deleteAll();
        _polylineAnnotations.clear();
      }
    } catch (e) {
      debugPrint('Error clearing route: $e');
    }
  }

  /// Vẽ route tới (lat, lng)
  Future<void> drawRouteTo(double lat, double lng) async {
    if (mapboxMap == null) {
      debugPrint('Map not ready yet');
      return;
    }

    try {
      if (currentLocation.value == null) {
        await goToCurrentLocation();
      }

      final cur = currentLocation.value;
      if (cur == null) {
        debugPrint('Không có currentLocation để làm origin');
        return;
      }

      final originLat = cur.coordinates.lat.toDouble();
      final originLng = cur.coordinates.lng.toDouble();

      final route = await MapboxService.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: lat,
        destLng: lng,
        profile: "driving",
      );

      if (route == null) {
        debugPrint('MapboxService trả về null route');
        return;
      }

      final rawCoords = route['geometry']?['coordinates'];
      if (rawCoords == null || rawCoords is! List || rawCoords.isEmpty) {
        debugPrint('Route geometry không hợp lệ');
        return;
      }

      final coordsList = <List<double>>[];
      for (final c in rawCoords) {
        if (c is List && c.length >= 2) {
          final lngVal = (c[0] as num).toDouble();
          final latVal = (c[1] as num).toDouble();
          coordsList.add([lngVal, latVal]);
        }
      }
      if (coordsList.isEmpty) {
        debugPrint('Không có coordinates để vẽ');
        return;
      }

      await _clearRoute();

      _polylineManager =
          await mapboxMap!.annotations.createPolylineAnnotationManager();

      final positions = coordsList.map((c) => Position(c[0], c[1])).toList();

      final lineOptions = PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: const Color(0xFF007AFF).value,
        lineWidth: 5.0,
      );

      final created = await _polylineManager!.create(lineOptions);
      _polylineAnnotations.add(created);

      final points = coordsList
          .map((c) => Point(coordinates: Position(c[0], c[1])))
          .toList();

      final camera = await mapboxMap?.cameraForCoordinates(
        points,
        MbxEdgeInsets(top: 170, left: 20, bottom: 170, right: 20),
        null,
        null,
      );
      if (camera != null) {
        await mapboxMap?.setCamera(camera);
      }

      final distance = (route['distance'] as num).toDouble();
      routeDistance.value = distance;
      hasActiveRoute.value = true;

      final duration = route['duration'];

      debugPrint('Route distance: $distance m, duration: $duration s');
    } catch (e) {
      debugPrint('Error in drawRouteTo: $e');
    }
  }

  Future<void> clearRoute() async {
    await _clearRoute();
    routeDistance.value = 0.0;
    hasActiveRoute.value = false;

    if (currentLocation.value != null) {
      await mapboxMap?.setCamera(CameraOptions(
        center: currentLocation.value,
        zoom: 17,
      ));
    }
  }

  // Selection Mode
  void startLocationSelection() {
    mapMode.value = MapMode.selecting;
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
      debugPrint("Error getting coordinates: $e");
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

  // Loading Spots by Bounding Box
  void onCameraChanged(CameraChangedEventData eventData) async {
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
          "Loaded $newCount new markers (cache=${_markerCacheById.length})");
    } catch (e) {
      debugPrint("Error loading markers: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllMarkers() async {
    if (_annotationManager == null) return;

    // Xóa annotations khỏi map
    await _annotationManager!.deleteAll();

    // Clear cache
    _markerCacheById.clear();
  }

  Future<void> reloadSpotsInView() async {
    final cameraState = await mapboxMap?.getCameraState();
    if (cameraState == null) return;

    final bounds = await mapboxMap?.coordinateBoundsForCamera(
      cameraState.toCameraOptions(),
    );
    if (bounds == null) return;

    if ((selectedCategory.value == null || selectedCategory.value!.isEmpty) &&
        searchQuery.value.isEmpty) {
      await clearAllMarkers();
      debugPrint("Clear marker");
      return;
    }

    await clearAllMarkers();
    await loadMarkersInView(bounds);
  }

  // Filter
  void updateCategory(String? category) {
    selectedCategory.value = category;
    reloadSpotsInView();
  }

  // Search
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    reloadSpotsInView();
  }

  Future<void> focusOnSpotsByName(
    String name, {
    required double currentLat,
    required double currentLng,
  }) async {
    final spotRepo = SpotRepository();

    // Lấy tất cả spots trùng tên
    final allSpots = await spotRepo.getSpotsByName(name);

    if (allSpots.isEmpty) {
      debugPrint("Không tìm thấy spot nào tên: $name");
      return;
    }

    // Nếu chỉ có 1 spot → focus luôn
    if (allSpots.length == 1) {
      final spot = allSpots.first;
      await mapboxMap?.setCamera(CameraOptions(
        center: Point(coordinates: Position(spot.longitude, spot.latitude)),
        zoom: 17.5,
      ));
      await addSpotMarker(spot);
      return;
    }

    // Tìm spot trong bán kính 10km tính từ spot đầu tiên
    final baseSpot = allSpots.first;
    final nearbySpots = allSpots.where((spot) {
      final distanceInMeters = geo.Geolocator.distanceBetween(
        baseSpot.latitude,
        baseSpot.longitude,
        spot.latitude,
        spot.longitude,
      );
      return distanceInMeters <= 10000;
    }).toList();

    // gom đủ trong 10km
    final spotsToFocus =
        (nearbySpots.length == allSpots.length) ? nearbySpots : allSpots;

    // Fit camera để thấy tất cả spot
    final points = spotsToFocus
        .map((s) => Point(coordinates: Position(s.longitude, s.latitude)))
        .toList();

    final camera = await mapboxMap?.cameraForCoordinates(
      points,
      MbxEdgeInsets(top: 170, left: 170, bottom: 170, right: 170),
      null,
      null,
    );

    if (camera != null) {
      await mapboxMap?.setCamera(camera);
    }

    // Add marker cho tất cả
    for (final spot in spotsToFocus) {
      await addSpotMarker(spot);
    }
  }

  // Marker click
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
                currentUserId,
              ),
              tag: spot.id,
            );
            return LocationCheckInsBottomSheet(
              spot: spot,
              currentUserId: currentUserId,
            );
          },
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      debugPrint("Error loading spot: $e");
    } finally {
      isBottomSheetOpen.value = false;
    }
  }
}
