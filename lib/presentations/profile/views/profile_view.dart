import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/auth/views/login_view.dart';
import 'package:app_snapspot/presentations/profile/controllers/profile_controller.dart';
import 'package:app_snapspot/presentations/profile/views/update_profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      if (authController.firebaseUser.value == null) {
        return const LoginView();
      }

      return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () => authController.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Obx(() {
          final profile = profileController.profile.value;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final effectivePhoto = profileController.effectivePhotoUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: (effectivePhoto != null && effectivePhoto.isNotEmpty)
                        ? NetworkImage(effectivePhoto)
                        : null,
                    child: (effectivePhoto == null || effectivePhoto.isEmpty)
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _showImagePickerOptions(profileController),
                    child: const Text("Thay đổi ảnh đại diện"),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile.displayName.isNotEmpty ? profile.displayName : 'No name',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(profile.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => const UpdateProfileView()),
                    icon: const Icon(Icons.edit),
                    label: const Text("Chỉnh sửa hồ sơ"),
                  ),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  void _showImagePickerOptions(ProfileController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Chụp ảnh"),
              onTap: () {
                Get.back();
                controller.pickAndUploadAvatar(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Chọn từ thư viện"),
              onTap: () {
                Get.back();
                controller.pickAndUploadAvatar(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}