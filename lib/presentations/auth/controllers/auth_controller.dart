import 'package:app_snapspot/domains/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rxn<User> firebaseUser = Rxn<User>();
  final ProfileRepository _repo = ProfileRepository();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled');
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        debugPrint('User signed in: UID=${user.uid}, Email=${user.email}');

        // Tạo ProfileModel và lưu qua repo
        final profile = ProfileModel(
          uid: user.uid,
          displayName: user.displayName ?? "",
          email: user.email ?? "",
          photoUrl: user.photoURL ?? "",
          isCustomAvatar: false,
        );

        await _repo.saveOrUpdateProfile(profile);
      }
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');
      Get.snackbar("Lỗi đăng nhập", e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error in signOut: $e');
      Get.snackbar("Lỗi đăng xuất", e.toString());
    }
  }
}
