  import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
  import 'package:get/get.dart';


  class AuthBinding extends Bindings {
    @override
    void dependencies() {
      Get.lazyPut<AuthController>(() => AuthController());
      Get.lazyPut<NavigationController>(() => NavigationController());
    }
  }
