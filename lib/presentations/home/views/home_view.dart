import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/presentations/home/controllers/navigation_controller.dart';
import 'package:app_snapspot/presentations/map/views/map_view.dart';
import 'package:app_snapspot/presentations/checkin_history/views/checkin_history_view.dart';
import 'package:app_snapspot/presentations/profile/views/profile_view.dart';
import 'package:app_snapspot/core/common_widgets/custom_bottom_nav.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';

class HomeView extends GetView<NavigationController> {
  HomeView({super.key});

  final List<Widget> pages = const [
    MapPage(),
    CheckInHistoryView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final i = controller.selectedIndex.value;
      final isLoggedIn = authController.firebaseUser.value != null;

      return Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          title: Text(
            i == 0
                ? "Bản đồ"
                : i == 1
                    ? "Lịch sử"
                    : isLoggedIn
                        ? "Hồ sơ người dùng"
                        : "Đăng nhập",
          ),
        ),
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
        bottomNavigationBar: CustomBottomNav(),
      );
    });
  }
}
