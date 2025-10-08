import 'package:app_snapspot/presentations/checkin_history/controllers/checkin_history_controller.dart';
import 'package:get/get.dart';

class CheckinHistoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CheckInHistoryController>()) {
      Get.lazyPut<CheckInHistoryController>(() => CheckInHistoryController());
    } else {
      Get.put(Get.find<CheckInHistoryController>(), permanent: true);
    }
  }
}
