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
        /// SORT
        PopupMenuButton<CheckInSortOption>(
          icon: const Icon(Icons.sort),
          initialValue: controller.sortOption,
          onSelected: controller.changeSort,
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
        ),

        /// TIME
        PopupMenuButton<CheckInTimeOption>(
          icon: const Icon(Icons.access_time),
          initialValue: controller.timeOption,
          onSelected: controller.changeTimeFilter,
          itemBuilder: (_) => const [
            PopupMenuItem(value: CheckInTimeOption.all, child: Text("Tất cả")),
            PopupMenuItem(
                value: CheckInTimeOption.last7Days,
                child: Text("7 ngày gần đây")),
            PopupMenuItem(
                value: CheckInTimeOption.last30Days,
                child: Text("30 ngày gần đây")),
          ],
        ),

        /// VIBE
        Obx(() => PopupMenuButton<String?>(
              icon: const Icon(Icons.mood),
              initialValue: controller.selectedVibeId.value,
              onSelected: controller.selectVibe,
              itemBuilder: (_) {
                return [
                  const PopupMenuItem(value: null, child: Text("Tất cả")),
                  ...controller.vibes.map(
                    (v) => PopupMenuItem(
                      value: v.id,
                      child: Text(v.name),
                    ),
                  )
                ];
              },
            )),
      ],
    );
  }
}
