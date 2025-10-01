import 'package:app_snapspot/core/common_widgets/custom_expandable_text.dart';
import 'package:app_snapspot/presentations/checkin/controllers/click_like_controller.dart';
import 'package:app_snapspot/presentations/checkin_history/views/update_checkin_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/presentations/checkin_history/controllers/checkin_history_controller.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';

class CheckInHistoryView extends StatelessWidget {
  const CheckInHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CheckInHistoryController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Obx(() {
        if (authController.firebaseUser.value == null) {
          return _buildNotLoggedInState();
        }

        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.checkins.isEmpty) {
          return _buildEmptyState();
        }

        return _buildCheckinList(controller);
      }),
    );
  }

  ///
  Widget _buildNotLoggedInState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text("Bạn chưa đăng nhập",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text("Đăng nhập để xem lịch sử check-in",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Get.toNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text("Đăng nhập"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
              )
            ],
          ),
        ),
      );

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Đang tải lịch sử check-in...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_history, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text("Chưa có lịch sử check-in",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text("Hãy bắt đầu check-in tại những địa điểm yêu thích!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      );

  ///
  Widget _buildCheckinList(CheckInHistoryController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchCheckIns(),
      child: ListView.builder(
        padding:
            const EdgeInsets.fromLTRB(8, 8, 8, kBottomNavigationBarHeight + 30),
        itemCount: controller.checkins.length,
        itemBuilder: (context, index) {
          final checkin = controller.checkins[index];
          return _buildCheckinCard(checkin, controller);
        },
      ),
    );
  }

  ///
  Widget _buildCheckinCard(
      CheckInModel checkin, CheckInHistoryController controller) {
    final clickLikeController = Get.put(
      ClickLikeController(checkin),
      tag: checkin.id,
      permanent: false,
    );

    final isSelected = controller.selectedCheckin.value == checkin;
    final formattedDate =
        DateFormat('dd/MM/yyyy • HH:mm').format(checkin.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.selectedCheckin(checkin),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên + ngày
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkin.name.isNotEmpty
                              ? checkin.name
                              : "(Không có tên)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút Update + Delete
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showUpdateCheckInSheet(
                          checkin,
                          onUpdated: () {
                            controller.fetchCheckIns();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Xóa",
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Xác nhận",
                            middleText: "Bạn có chắc muốn xóa check-in này?",
                            textCancel: "Hủy",
                            textConfirm: "Xóa",
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              controller.deleteCheckIn(checkin.id);
                              Get.back();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category + Vibe + Like/Dislike
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (checkin.categoryIcon.isNotEmpty)
                        Chip(
                          label: Text(checkin.categoryName),
                          avatar: Image.network(
                            checkin.categoryIcon,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(checkin.vibeName),
                        avatar: Text(
                          checkin.vibeIcon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Like/Dislike
                  Obx(() {
                    return Row(
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 18,
                          color: clickLikeController.isLiked.value
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text("${clickLikeController.likesCount.value}"),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.thumb_down,
                          size: 18,
                          color: clickLikeController.isDisliked.value
                              ? Colors.red
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text("${clickLikeController.dislikesCount.value}"),
                      ],
                    );
                  }),
                ],
              ),

              // Content
              if (checkin.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpandableText(
                    text: checkin.content,
                    trimLines: 2,
                  ),
                ),
              ],

              // Images
              if (checkin.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: checkin.images.length,
                    itemBuilder: (context, imageIndex) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            checkin.images[imageIndex],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Address when selected
              Obx(() {
                final address =
                    controller.addresses[checkin.id] ?? "Đang tải...";
                return Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(address,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          )),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
