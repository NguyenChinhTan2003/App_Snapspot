import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomFilterBar extends StatelessWidget {
  final LocationCheckInsController controller;
  const CustomFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sort filter
        Obx(() => PopupMenuButton<CheckInSortOption>(
              icon: const Icon(Icons.sort),
              tooltip: "Sắp xếp",
              initialValue: controller.sortOption.value,
              onSelected: controller.setSort,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: CheckInSortOption.newest, child: Text("Mới nhất")),
                PopupMenuItem(
                    value: CheckInSortOption.oldest, child: Text("Cũ nhất")),
                PopupMenuItem(
                    value: CheckInSortOption.mostLiked,
                    child: Text("Nhiều like nhất")),
                PopupMenuItem(
                    value: CheckInSortOption.mostDisliked,
                    child: Text("Nhiều dislike nhất")),
              ],
            )),

        // Time filter
        Obx(() => PopupMenuButton<CheckInTimeOption>(
              icon: const Icon(Icons.access_time),
              tooltip: "Thời gian",
              initialValue: controller.timeOption.value,
              onSelected: controller.setTime,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: CheckInTimeOption.all, child: Text("Tất cả")),
                PopupMenuItem(
                    value: CheckInTimeOption.last7Days,
                    child: Text("7 ngày gần đây")),
                PopupMenuItem(
                    value: CheckInTimeOption.last30Days,
                    child: Text("30 ngày gần đây")),
              ],
            )),

        // Vibe filter
        Obx(() => PopupMenuButton<CheckInVibeOption>(
              icon: const Icon(Icons.mood),
              tooltip: "Vibe",
              initialValue: controller.vibeOption.value,
              onSelected: controller.setVibe,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: CheckInVibeOption.all, child: Text("Tất cả")),
                PopupMenuItem(
                    value: CheckInVibeOption.thugian, child: Text("Thư giãn")),
                PopupMenuItem(
                    value: CheckInVibeOption.vuive, child: Text("Vui vẻ")),
                PopupMenuItem(
                    value: CheckInVibeOption.yeuduong, child: Text("Yêu")),
                PopupMenuItem(
                    value: CheckInVibeOption.bucxuc, child: Text("Bức xúc")),
              ],
            )),
      ],
    );
  }
}
