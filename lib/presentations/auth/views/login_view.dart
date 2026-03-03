import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton.icon(
          onPressed: () => controller.signInWithGoogle(),
          icon: const Icon(Icons.login),
          label: const Text("Đăng nhập với Google"),
        ),
      );
  }
}
