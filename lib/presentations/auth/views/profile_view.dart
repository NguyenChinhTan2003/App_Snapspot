import 'package:app_snapspot/core/common_widgets/custom_bottom_nav.dart';
import 'package:app_snapspot/core/common_widgets/custom_stat_box.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.firebaseUser.value;

      //chưa đăng nhập
      if (user == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "Bạn chưa đăng nhập",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => controller.signInWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: const Text("Đăng nhập bằng Google"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(),
        );
      }

      // đã đăng nhập
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: Colors.green.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          (user.photoURL != null && user.photoURL!.isNotEmpty)
                              ? NetworkImage(user.photoURL!)
                              : null,
                      child: (user.photoURL == null || user.photoURL!.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      user.displayName ?? "Người dùng",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomStatBox(title: "Địa điểm đã up", value: "12"),
                  SizedBox(width: 20),
                  CustomStatBox(title: "Tym", value: "50", color: Colors.pink),
                ],
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Chỉnh sửa hồ sơ"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.orange),
                title: const Text("Hỗ trợ"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => controller.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Đăng xuất"),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(),
      );
    });
  }
}
