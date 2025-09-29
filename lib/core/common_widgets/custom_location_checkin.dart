import 'package:app_snapspot/core/common_widgets/custom_detail_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_filter_bar.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/presentations/checkin/controllers/click_like_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:app_snapspot/presentations/profile/views/profile_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/spot_model.dart';

class LocationCheckInsBottomSheet extends StatelessWidget {
  final SpotModel spot;
  final String? currentUserId;
  const LocationCheckInsBottomSheet(
      {super.key, required this.spot, this.currentUserId});

  void _showCheckInDetail(BuildContext context, checkin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CheckInBottomSheet(
          checkin: checkin,
          currentUserId: currentUserId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        debugPrint("👉 Current UserId trong BottomSheet: $currentUserId");

        final controller = Get.find<LocationCheckInsController>(tag: spot.id);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  spot.name ?? "Danh sách Check-in",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Filter bar
              CustomFilterBar(controller: controller),
              const Divider(height: 1),

              // Content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error.value != null) {
                    return Center(
                        child: Text("Lỗi: ${controller.error.value}"));
                  }
                  if (controller.checkins.isEmpty) {
                    return const Center(
                        child: Text("Chưa có check-in nào tại Spot này"));
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchCheckIns,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.checkins.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final enhanced = controller.checkins[index];
                        final checkin = enhanced.checkIn;
                        final profile = enhanced.profile;
                        final category = enhanced.category;
                        final vibe = enhanced.vibe;
                        final formattedDate = DateFormat('dd/MM/yyyy • HH:mm')
                            .format(checkin.createdAt);
                        final clickLikeController = Get.put(
                          ClickLikeController(
                            checkin,
                            currentUserId: currentUserId,
                          ),
                          tag: checkin.id,
                          permanent: false,
                        );

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showCheckInDetail(context, checkin),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (profile != null) {
                                            if (currentUserId != null &&
                                                currentUserId == profile.uid) {
                                              return;
                                            }
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  insetPadding:
                                                      const EdgeInsets.all(16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                  ),
                                                  child: SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.55,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.85,
                                                    child: ProfilePublic(
                                                        uid: profile.uid),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundImage: profile?.photoUrl !=
                                                  null
                                              ? NetworkImage(profile!.photoUrl!)
                                              : null,
                                          backgroundColor: Colors.grey[300],
                                          child: profile?.photoUrl == null
                                              ? const Icon(Icons.person,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  profile?.displayName ??
                                                      "Ẩn danh",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Image
                                  if (checkin.images.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          checkin.images.first,
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                  // Title
                                  if (checkin.name.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        checkin.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  // Chips + Like/Dislike count
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Chips
                                      Row(
                                        children: [
                                          if (category != null)
                                            Chip(
                                              label: Text(category.name),
                                              avatar: Image.network(
                                                category.iconUrl,
                                                width: 20,
                                              ),
                                            ),
                                          if (vibe != null)
                                            Chip(
                                              label: Text(vibe.name),
                                              avatar: Text(
                                                checkin.vibeIcon,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const Spacer(),

                                      // Hiển thị lượt like/dislike
                                      Obx(() {
                                        return Row(
                                          children: [
                                            Icon(
                                              Icons.thumb_up,
                                              size: 18,
                                              color: clickLikeController
                                                      .isLiked.value
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                                "${clickLikeController.likesCount.value}"),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.thumb_down,
                                              size: 18,
                                              color: clickLikeController
                                                      .isDisliked.value
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                                "${clickLikeController.dislikesCount.value}"),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
