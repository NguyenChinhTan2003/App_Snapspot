import 'package:app_snapspot/core/common_widgets/custom_expandable_text.dart';
import 'package:app_snapspot/core/common_widgets/custom_images_view.dart';
import 'package:app_snapspot/core/common_widgets/format_count.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/click_like_controller.dart';
import 'package:app_snapspot/presentations/profile/views/profile_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_detail_controller.dart';

class CheckInBottomSheet extends StatelessWidget {
  final CheckInModel checkin;

  const CheckInBottomSheet({super.key, required this.checkin});

  void _showProfile(BuildContext context, String uid) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SizedBox(
          height: size.height * 0.55,
          width: size.width * 0.85,
          child: ProfilePublic(uid: uid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CheckInDetailController(checkin.userId, checkin),
      tag: checkin.id,
    );

    final likeController = Get.put(
      ClickLikeController(checkin),
      tag: "like-${checkin.id}",
    );

    final formattedDate =
        DateFormat('dd/MM/yyyy - HH:mm').format(checkin.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final user = controller.user.value;
          final isLoading = controller.isLoading.value;
          final currentUserId = likeController.currentUserId.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              // Header: Avatar + Name + Time
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user != null && currentUserId != user.uid) {
                        _showProfile(context, user.uid);
                      }
                    },
                    child: CircleAvatar(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (user != null && currentUserId != user.uid) {
                                  _showProfile(context, user.uid);
                                }
                              },
                              child: Text(
                                user?.displayName ??
                                    (isLoading ? "Đang tải..." : "Ẩn danh"),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Text(formattedDate,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main Image
              if (checkin.images.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomImagesView(
                          imageUrls: checkin.images,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: checkin.images.first,
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
                ),

              const SizedBox(height: 16),

              // Category + Vibe
              Row(
                children: [
                  if (checkin.categoryIcon.isNotEmpty)
                    Chip(
                      label: Text(checkin.categoryName),
                      avatar: Image.network(checkin.categoryIcon,
                          width: 20, height: 20),
                    ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(checkin.vibeName),
                    avatar: Text(checkin.vibeIcon,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Place name
              Row(
                children: [
                  const Text("Tên địa điểm: ",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(checkin.name,
                          style: const TextStyle(fontSize: 14))),
                ],
              ),

              const SizedBox(height: 10),

              // Address + Copy
              Obx(() {
                return Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        controller.address.value,
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          controller.copied.value ? Icons.check : Icons.copy,
                          color: controller.copied.value
                              ? Colors.green
                              : Colors.grey,
                          size: 18),
                      onPressed: () {
                        controller.copyAddress();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã copy địa chỉ")),
                        );
                      },
                    ),
                  ],
                );
              }),

              const SizedBox(height: 12),

              // Content
              if (checkin.content.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpandableText(text: checkin.content, trimLines: 2),
                ),

              const SizedBox(height: 12),

              // Like / Dislike
              Row(
                children: [
                  const Spacer(),
                  Obx(() => IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: likeController.isLiked.value
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        onPressed: () => likeController.toggleReaction("like"),
                      )),
                  Obx(() => Text(
                        formatCountAdvanced(likeController.likesCount.value),
                        style: const TextStyle(fontSize: 13),
                      )),
                  const SizedBox(width: 8),
                  Obx(() => IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: likeController.isDisliked.value
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () =>
                            likeController.toggleReaction("dislike"),
                      )),
                  Obx(() => Text(
                        formatCountAdvanced(likeController.dislikesCount.value),
                        style: const TextStyle(fontSize: 13),
                      )),
                ],
              ),

              const SizedBox(height: 16),

              // Additional images
              if (checkin.images.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ảnh khác",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: checkin.images.length - 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final imgUrl = checkin.images[index + 1];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomImagesView(
                                    imageUrls: checkin.images,
                                    initialIndex: index + 1,
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: imgUrl,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imgUrl,
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
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
