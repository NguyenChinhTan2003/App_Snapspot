import 'package:app_snapspot/presentations/checkin/controllers/checkin_controller.dart';
import 'package:get/get.dart';



class CheckinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckinController>(
      () => CheckinController(),
    );
  }
}