import 'package:app_snapspot/applications/services/auth_service.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    firebaseUser.value = _authService.currentUser;
    super.onInit();
  }

  Future<void> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      firebaseUser.value = user;
      Get.snackbar("Success", "Đăng nhập thành công: ${user.displayName}");
    } else {
      Get.snackbar("Error", "Đăng nhập thất bại hoặc bị hủy.");
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    firebaseUser.value = null;
    Get.snackbar("Logout", "Bạn đã đăng xuất.");
  }
}
