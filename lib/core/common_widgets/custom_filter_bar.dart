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
                    child: Text("Nhiều Like nhất")),
                PopupMenuItem(
                    value: CheckInSortOption.mostDisliked,
                    child: Text("Nhiều UnLike nhất")),
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
        Obx(() {
          return PopupMenuButton<String?>(
            icon: const Icon(Icons.mood),
            tooltip: "Vibe",
            initialValue: controller.selectedVibeId.value ?? 'all',
            onSelected: controller.setVibe,
            itemBuilder: (_) {
              final items = <PopupMenuEntry<String?>>[
                const PopupMenuItem(
                  value: 'all',
                  child: Text("Tất cả"),
                ),
              ];
              items.addAll(controller.vibes.map((vibe) {
                return PopupMenuItem(
                  value: vibe.id,
                  child: Text(vibe.name),
                );
              }).toList());
              return items;
            },
          );
        }),
      ],
    );
  }
}
