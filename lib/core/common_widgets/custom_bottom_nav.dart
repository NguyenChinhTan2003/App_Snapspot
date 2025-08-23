import 'package:get/get.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  CustomBottomNav({super.key});

  final nav = Get.find<NavigationController>();
  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggedIn = auth.firebaseUser.value != null;

      return BottomNavigationBar(
        currentIndex: nav.selectedIndex.value,
        onTap: nav.changeIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(isLoggedIn ? Icons.person : Icons.login),
            label: isLoggedIn ? 'Profile' : 'Login',
          ),
        ],
      );
    });
  }
}
