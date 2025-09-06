import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:get/get.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapController>(
      () => MapController(),
    );
    Get.lazyPut<NavigationController>(() => NavigationController());
  }
}