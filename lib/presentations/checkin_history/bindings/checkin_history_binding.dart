import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_detail_controller.dart';
import 'package:app_snapspot/presentations/checkin_history/controllers/checkin_history_controller.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:get/get.dart';

class CheckinHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<CheckInDetailController>(() => CheckInDetailController(
        Get.find<CheckInHistoryController>().userId!,
        Get.arguments!['checkin']));
  }
}
