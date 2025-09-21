import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_detail_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:get/get.dart';

class CheckinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckinController>(
      () => CheckinController(),
    );
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<LocationCheckInsController>(() => LocationCheckInsController(
        CheckInRepository(), Get.arguments['spotId']));
    Get.lazyPut<CheckInDetailController>(() => CheckInDetailController(
        Get.arguments['userId'] ?? Get.arguments['checkin'].userId));
  }
}
