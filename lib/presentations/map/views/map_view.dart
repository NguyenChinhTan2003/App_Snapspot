import 'package:app_snapspot/core/common_widgets/custom_crosshair.dart';
import 'package:app_snapspot/presentations/map/views/custom_search_filter_bar.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends GetView<MapController> {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final token = controller.mapboxToken.value;
      final location = controller.currentLocation.value;

      if (token == null || location == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                "Đang tải bản đồ...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: controller.onMapCreated,
            onCameraChangeListener: controller.onCameraChanged,
            cameraOptions: CameraOptions(
              center: location,
              zoom: 15.0,
            ),
          ),

          Obx(() {
            if (controller.hasActiveRoute.value) {
              final km =
                  (controller.routeDistance.value / 1000).toStringAsFixed(1);

              return Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Khoảng cách: $km km",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: controller.clearRoute,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text("Hủy",
                            style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Thanh search + filter categories
          Obx(() {
            if (controller.mapMode.value == MapMode.selecting) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: CustomSearchFilterBar(
                onSearch: (searchText, categoryId) {
                  controller.updateCategory(
                    categoryId.isNotEmpty ? categoryId : null,
                  );

                  if (searchText.isNotEmpty) {
                    final loc = controller.currentLocation.value;
                    if (loc != null) {
                      controller.focusOnSpotsByName(
                        searchText,
                        currentLat: loc.coordinates.lat.toDouble(),
                        currentLng: loc.coordinates.lng.toDouble(),
                      );
                    }
                  } else {
                    controller.updateSearchQuery(searchText);
                  }
                },
              ),
            );
          }),

          // Crosshair khi chọn vị trí
          if (controller.mapMode.value == MapMode.selecting)
            const Positioned.fill(
              child: CustomCrosshair(),
            ),

          // Hướng dẫn chọn vị trí
          if (controller.mapMode.value == MapMode.selecting)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Di chuyển bản đồ để chọn vị trí mong muốn của bạn. Nhấn "Xác nhận" để lưu vị trí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

          Obx(() {
            if (controller.isAddButtonVisible.value &&
                controller.mapMode.value != MapMode.selecting) {
              return Positioned(
                right: 16,
                bottom: 120,
                child: Column(
                  children: [
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      heroTag: "toggleMapStyle",
                      onPressed: controller.toggleMapStyle,
                      child: Obx(() => Icon(
                            controller.isSatelliteMode.value
                                ? Icons.map
                                : Icons.satellite_alt,
                            size: 22,
                          )),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      heroTag: "currentLocation",
                      onPressed: () {
                        controller.goToCurrentLocation();
                        controller.isCompassVisible.value = true;
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 12),
                    controller.hasActiveRoute.value
                        ? const SizedBox(height: 56)
                        : FloatingActionButton(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            heroTag: "addLocation",
                            onPressed: controller.startLocationSelection,
                            child: const Icon(Icons.add_location, size: 28),
                          ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Nút confirm/cancel khi chọn vị trí
          if (controller.mapMode.value == MapMode.selecting)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.cancelLocationSelection,
                      icon: const Icon(Icons.close),
                      label: const Text('Hủy bỏ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.confirmLocationSelection,
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
