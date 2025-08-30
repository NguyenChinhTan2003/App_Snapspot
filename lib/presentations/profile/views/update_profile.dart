
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateProfileView extends StatelessWidget {
  const UpdateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    Get.find<AuthController>();

    final nameController =
        TextEditingController(text: profileController.displayName);

    return Scaffold(
      appBar: AppBar(title: const Text("Cập nhật hồ sơ")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() {
              final effectivePhoto = profileController.effectivePhotoUrl;
              return GestureDetector(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      (effectivePhoto != null && effectivePhoto.isNotEmpty)
                          ? NetworkImage(effectivePhoto)
                          : null,
                  child: (effectivePhoto == null || effectivePhoto.isEmpty)
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên hiển thị"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;

                await profileController.updateDisplayName(newName);
                Get.back();
              },
              child: const Text("Lưu"),
            )
          ],
        ),
      ),
    );
  }

  
}
