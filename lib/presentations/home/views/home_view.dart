import 'package:app_snapspot/core/common_widgets/custom_bottom_nav.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/profile/views/profile_view.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:app_snapspot/presentations/map/views/history_view.dart';
import 'package:app_snapspot/presentations/map/views/map_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<NavigationController> {
  const HomeView({super.key});

  final List<Widget> pages = const [
    MapPage(),
    HistoryView(),
    ProfileView()
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          switch (controller.selectedIndex.value) {
            case 0:
              return AppBar(
                title: const Text("Bản đồ"),
                backgroundColor: Colors.green,
                centerTitle: true,
              );
            case 1:
              return AppBar(
                title: const Text("Lịch sử"),
                backgroundColor: Colors.green,
                centerTitle: true,
              );
            case 2:
             return Obx(() {
                final isLoggedIn = authController.firebaseUser.value != null;
                return AppBar(
                  title: Text(isLoggedIn ? "Hồ sơ người dùng" : "Đăng nhập"),
                  backgroundColor: Colors.green,
                  centerTitle: true,
                );
              });
            default:
              return AppBar(
                title: const Text("SnapSpot"),
                backgroundColor: Colors.green,
                centerTitle: true,
              );
          }
        }),
      ),
      body: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: IndexedStack(
            key: ValueKey(controller.selectedIndex.value),
            index: controller.selectedIndex.value,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(),
    );
  }
}
