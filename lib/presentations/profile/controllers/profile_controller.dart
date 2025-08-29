import 'dart:io';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/domains/repositories/profile_repository.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final ProfileRepository _repository = ProfileRepository();
  Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);
  final RxnString _googlePhoto = RxnString();

  String get displayName => profile.value?.displayName ?? '';
  String get email => profile.value?.email ?? '';
  String? get photoUrl => profile.value?.photoUrl;

  // Ưu tiên avatar tùy chỉnh dựa trên isCustomAvatar
  String? get effectivePhotoUrl {
    if (profile.value?.isCustomAvatar == true && profile.value?.photoUrl != null) {
      return profile.value!.photoUrl;
    }
    return _googlePhoto.value;
  }

  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().firebaseUser, _handleAuthChanged);

    final user = Get.find<AuthController>().firebaseUser.value;
    if (user != null) {
      _handleAuthChanged(user);
    }
  }

  void _handleAuthChanged(user) async {
    if (user != null) {
      final uid = user.uid;
      final email = user.email ?? '';
      final name = user.displayName ?? '------';
      _googlePhoto.value = user.photoURL; 

      var data = await _repository.getProfile(uid);

      if (data == null) {

        final newProfile = ProfileModel(
          uid: uid,
          displayName: name,
          email: email,
          photoUrl: null,
          isCustomAvatar: false,
        );
        await _repository.saveProfile(newProfile);
        profile.value = newProfile;
      } else {
       
        if (data.displayName != name || data.email != email) {
          final updatedProfile = data.copyWith(
            displayName: name,
            email: email,
          );
          await _repository.saveProfile(updatedProfile);
          profile.value = updatedProfile;
        } else {
          profile.value = data;
        }
      }
    } else {
      profile.value = null;
      _googlePhoto.value = null;
    }
  }

  Future<void> saveProfile(ProfileModel profileModel) async {
    await _repository.saveProfile(profileModel);
    profile.value = profileModel;
  }

  Future<void> pickAndUploadAvatar({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uid = Get.find<AuthController>().firebaseUser.value?.uid;

      if (uid != null) {
        final uploadedUrl = await _repository.uploadAvatar(uid, file);
        if (uploadedUrl != null) {
     
          await _repository.updateFields(
            uid,
            photoUrl: uploadedUrl,
            isCustomAvatar: true,
          );

   
          final current = profile.value;
          if (current != null) {
            profile.value = current.copyWith(
              photoUrl: uploadedUrl,
              isCustomAvatar: true,
            );
          } else {
            profile.value = await _repository.getProfile(uid);
          }
        }
      }
    }
  }

  Future<void> updateDisplayName(String newName) async {
  final uid = Get.find<AuthController>().firebaseUser.value?.uid;
  if (uid == null) return;
  final trimmed = newName.trim();
  if (trimmed.isEmpty) return;

  await _repository.updateFields(
    uid,
    displayName: trimmed,
  );

  final current = profile.value;
  if (current != null) {
    profile.value = current.copyWith(displayName: trimmed);
  }
}

}