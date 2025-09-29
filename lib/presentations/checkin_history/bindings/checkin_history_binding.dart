

import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:get/get.dart';

class CheckinHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());

  }
}
