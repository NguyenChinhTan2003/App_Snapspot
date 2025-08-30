import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);
      User? user = userCred.user;

      if (user != null) {
        print('User signed in: UID=${user.uid}, Email=${user.email}');
        await _saveUserProfile(user);
      } else {
        print('No user returned from sign-in');
      }
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      Get.snackbar("Lỗi đăng nhập", e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      print('User signed out');
    } catch (e) {
      print('Error in signOut: $e');
      Get.snackbar("Lỗi đăng xuất", e.toString());
    }
  }

  /// Lưu hồ sơ người dùng vào Firestore
  Future<void> _saveUserProfile(User user) async {
    try {
      final db = FirebaseFirestore.instance;
      final docRef = db.collection("profiles").doc(user.uid);
      
      // Kiểm tra xem hồ sơ đã tồn tại chưa
      final doc = await docRef.get();
      if (doc.exists && doc.data()?['isCustomAvatar'] == true) {

        print('Existing profile with custom avatar found for UID: ${user.uid}');
        await docRef.set({
          "uid": user.uid,
          "email": user.email,
        }, SetOptions(merge: true));
      } else {
   
        print('Creating/updating profile for UID: ${user.uid}');
        await docRef.set({
          "uid": user.uid,
          "name": user.displayName ?? "",
          "email": user.email,
          "photoUrl": null, 
          "isCustomAvatar": false,
          "createdAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      print('Profile saved successfully for UID: ${user.uid}');
    } catch (e) {
      print('Error in _saveUserProfile: $e');
      Get.snackbar("Lỗi lưu hồ sơ", e.toString());
      rethrow;
    }
  }
}