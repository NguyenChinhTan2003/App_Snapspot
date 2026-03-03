import 'package:app_snapspot/presentations/checkin_history/controllers/checkin_history_controller.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;

    if (index == 1) {
      final historyController = Get.find<CheckInHistoryController>();
      historyController.fetchCheckIns();
    }
  }
}
