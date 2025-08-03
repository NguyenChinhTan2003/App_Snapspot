import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MapController()); 

    return Scaffold(
      appBar: AppBar(title: const Text("App SnapSpot")),
      body: Obx(() {
        final token = controller.mapboxToken.value;

        if (token == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return MapWidget(
          key: const ValueKey("mapWidget"),
          onMapCreated: controller.onMapCreated,
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(106.660172, 10.762622),
            ),
            zoom: 14.0,
          ),
        );
      }),
    );
  }
}
