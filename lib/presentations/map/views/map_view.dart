import 'package:app_snapspot/core/common_widgets/custom_bottom_nav.dart';
import 'package:app_snapspot/core/common_widgets/custom_crosshair.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.put(MapController());
    final navController = Get.put(NavigationController());

    return Scaffold(
      extendBody: true, // Để bottom nav có thể overlap với body
      appBar: AppBar(
        title: const Text(
          "App SnapSpot",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() => _buildBody(navController, mapController)),
      bottomNavigationBar: CustomBottomNav(),
    );
  }

  Widget _buildBody(NavigationController navController, MapController mapController) {
    switch (navController.selectedIndex.value) {
      case 0:
        return _buildMapView(mapController);
      case 1:
        return _buildCameraView();
      case 2:
        return _buildGalleryView();
      case 3:
        return _buildProfileView();
      default:
        return _buildMapView(mapController);
    }
  }

  Widget _buildMapView(MapController mapController) {
    return Obx(() {
      final token = mapController.mapboxToken.value;

      if (token == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                "Loading Map...",
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
            onMapCreated: mapController.onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(106.660172, 10.762622),
              ),
              zoom: 14.0,
            ),
          ),
           // Crosshair for location selection
          if (mapController.mapMode.value == MapMode.selecting)
            const Positioned.fill(
              child: CustomCrosshair(),
            ),

          // Selection instructions
          if (mapController.mapMode.value == MapMode.selecting)
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

          // Add Location Button
          if (mapController.isAddButtonVisible.value)
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  // Current location button
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    heroTag: "currentLocation",
                    onPressed: () {
                      // Add current location functionality
                    },
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 12),
                  // Add location button
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    heroTag: "addLocation",
                    onPressed: mapController.startLocationSelection,
                    child: const Icon(Icons.add_location, size: 28),
                  ),
                ],
              ),
            ),

          // Confirm/Cancel buttons for selection mode
          if (mapController.mapMode.value == MapMode.selecting)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: mapController.cancelLocationSelection,
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
                      onPressed: mapController.confirmLocationSelection,
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

  Widget _buildCameraView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_location_alt,
            size: 80,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            'Location',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Đăng ảnh và vibe của bạn!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu,
            size: 80,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            'History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Danh sách các địa điểm đã đến',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green,
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Quản lý thông tin cá nhân của bạn',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}