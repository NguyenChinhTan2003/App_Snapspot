import 'package:app_snapspot/domains/repositories/category_repository.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/checkin_history/controllers/checkin_history_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/search_filter_controller.dart';
import 'package:app_snapspot/presentations/profile/controllers/profile_controller.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<CheckInHistoryController>(() => CheckInHistoryController());

    Get.lazyPut<CategoryRepository>(() => CategoryRepository());
    Get.lazyPut<SearchFilterController>(
      () => SearchFilterController(Get.find<CategoryRepository>()),
    );
  }
}
