import 'dart:ui';
import 'package:app_snapspot/applications/services/mapbox_service.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DirectionsController extends GetxController {
  final distanceKm = "".obs;
  final durationMin = "".obs;
  final routeCoordinates = <List<double>>[].obs;

  final MapController mapController = Get.find<MapController>();

  /// Hàm chỉ đường từ vị trí hiện tại tới 1 điểm (spot)
  Future<void> getDirections(double destLat, double destLng) async {
    try {
      final pos = await mapController.goToCurrentLocation();
      if (pos == null) return;

      final route = await MapboxService.getRoute(
        originLat: pos.latitude.toDouble(),
        originLng: pos.longitude.toDouble(),
        destLat: destLat,
        destLng: destLng,
        profile: "driving",
      );

      if (route != null) {
        // Lưu polyline
        final coords = List<List<double>>.from(
          route["geometry"]["coordinates"].map<List<double>>(
            (c) => [c[0].toDouble(), c[1].toDouble()],
          ),
        );

        routeCoordinates.assignAll(coords);

        // Lưu thông tin distance/duration
        distanceKm.value = (route["distance"] / 1000).toStringAsFixed(1);
        durationMin.value = (route["duration"] / 60).toStringAsFixed(0);
      }
    } catch (e) {
      print("Error getting directions: $e");
    }
  }

  /// Vẽ tuyến đường lên bản đồ
  Future<void> drawRoute(MapboxMap mapboxMap) async {
    if (routeCoordinates.isEmpty) return;

    // cần await vì hàm trả về Future<PolylineAnnotationManager>
    final manager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    final lineOptions = PolylineAnnotationOptions(
      geometry: LineString(
        coordinates: routeCoordinates.map((c) {
          return Position(c[0], c[1]); // lng, lat
        }).toList(),
      ),
      lineColor: const Color(0xFF007AFF).value, // xanh iOS style
      lineWidth: 5.0,
    );

    await manager.create(lineOptions);
  }
}
