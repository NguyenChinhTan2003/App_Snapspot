import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class UpdateProfileSheet extends StatelessWidget {
  const UpdateProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    Get.find<AuthController>();

    final nameController =
        TextEditingController(text: profileController.displayName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Wrap(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Tên hiển thị",
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[\p{L}0-9\s]', unicode: true)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;

                await profileController.updateDisplayName(newName);
                Get.back();
              },
              child: const Text("Lưu", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
