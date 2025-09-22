import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/click_like_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_detail_controller.dart';

class CheckInBottomSheet extends StatelessWidget {
  final CheckInModel checkin;
  final String? currentUserId;

  const CheckInBottomSheet(
      {super.key, required this.checkin, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final controller = Get.put(
      CheckInDetailController(checkin.userId, checkin),
      tag: checkin.id,
    );

    final likeController = Get.put(
      ClickLikeController(
        repo: CheckInRepository(),
        checkin: checkin,
        currentUserId: authController.firebaseUser.value?.uid,
      ),
      tag: "like-${checkin.id}",
    );

    final formattedDate =
        DateFormat('dd/MM/yyyy • HH:mm').format(checkin.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Obx(() {
          final user = controller.user.value;
          final isLoading = controller.isLoading.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Header: Người đăng + Thời gian
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : (user?.photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.displayName ??
                                  (isLoading ? "Đang tải..." : "Ẩn danh"),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ảnh chính
              if (checkin.images.isNotEmpty)
                Hero(
                  tag: "checkin-${checkin.id}",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      checkin.images.first,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Category + Vibe + Like/Dislike
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (checkin.categoryIcon.isNotEmpty)
                        Chip(
                          label: Text(checkin.categoryId),
                          avatar: Image.network(
                            checkin.categoryIcon,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(checkin.vibeId),
                        avatar: Text(
                          checkin.vibeIcon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Like/Dislike buttons
                  Obx(() {
                    final likedColor =
                        (likeController.hasLoadedUserReaction.value &&
                                likeController.isLiked.value)
                            ? Colors.blue
                            : Colors.grey;
                    final dislikedColor =
                        (likeController.hasLoadedUserReaction.value &&
                                likeController.isDisliked.value)
                            ? Colors.red
                            : Colors.grey;

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: likedColor,
                          ),
                          onPressed: () => likeController.toggleLike(),
                        ),
                        Text("${likeController.likesCount.value}"),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.thumb_down,
                            color: dislikedColor,
                          ),
                          onPressed: () => likeController.toggleDislike(),
                        ),
                        Text("${likeController.dislikesCount.value}"),
                      ],
                    );
                  }),
                ],
              ),

              const SizedBox(height: 12),

              // Tên địa điểm
              Row(
                children: [
                  const Text("Tên địa điểm : ",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Text(checkin.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.normal)),
                ],
              ),
              const SizedBox(height: 10),

              // Địa chỉ từ MapboxService
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.address.value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Nội dung
              if (checkin.content.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    checkin.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              const SizedBox(height: 16),

              // Ảnh phụ
              if (checkin.images.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ảnh khác",
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: checkin.images.length - 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            checkin.images[index + 1],
                            width: 120,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }
}
