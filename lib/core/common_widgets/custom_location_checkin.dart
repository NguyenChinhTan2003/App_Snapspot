import 'package:app_snapspot/core/common_widgets/custom_detail_checkin.dart';
import 'package:app_snapspot/core/common_widgets/custom_filter_bar.dart';
import 'package:app_snapspot/core/common_widgets/format_count.dart';
import 'package:app_snapspot/presentations/checkin/controllers/click_like_controller.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:app_snapspot/presentations/map/controllers/map_controller.dart';
import 'package:app_snapspot/presentations/profile/views/profile_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/spot_model.dart';

class LocationCheckInsBottomSheet extends StatefulWidget {
  final SpotModel spot;
  final String? currentUserId;

  const LocationCheckInsBottomSheet({
    super.key,
    required this.spot,
    this.currentUserId,
  });

  @override
  State<LocationCheckInsBottomSheet> createState() =>
      _LocationCheckInsBottomSheetState();
}

class _LocationCheckInsBottomSheetState
    extends State<LocationCheckInsBottomSheet> {
  late final LocationCheckInsController controller;
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LocationCheckInsController>(tag: widget.spot.id);
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _showCheckInDetail(checkin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInBottomSheet(checkin: checkin),
    );
  }

  void _showProfile(String uid) {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollSheetController) => Container(
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
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.spot.name ?? "Danh sách Check-in",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blue),
                    tooltip: "Chỉ đường",
                    onPressed: () async {
                      Navigator.of(context).pop();

                      final mapController = Get.find<MapController>();

                      // xoá các marker khác, chỉ giữ lại marker điểm đến
                      await mapController
                          .keepOnlyDestinationMarker(widget.spot);

                      // vẽ tuyến đường
                      await mapController.drawRouteTo(
                        widget.spot.latitude,
                        widget.spot.longitude,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CustomFilterBar(controller: controller),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null) {
                  return Center(child: Text("Lỗi: ${controller.error.value}"));
                }
                if (controller.displayedCheckins.isEmpty) {
                  return const Center(
                      child: Text("Chưa có check-in nào tại Spot này"));
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchCheckIns,
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.displayedCheckins.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      if (index == controller.displayedCheckins.length) {
                        return controller.isLoadingMore.value
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox();
                      }

                      final enhanced = controller.displayedCheckins[index];
                      final checkin = enhanced.checkIn;
                      final profile = enhanced.profile;
                      final category = enhanced.category;
                      final vibe = enhanced.vibe;

                      final clickLikeController = Get.put(
                        ClickLikeController(checkin),
                        tag: checkin.id,
                        permanent: false,
                      );

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _showCheckInDetail(checkin),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (profile != null &&
                                            widget.currentUserId !=
                                                profile.uid) {
                                          _showProfile(profile.uid);
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
                                              Flexible(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (profile != null &&
                                                        widget.currentUserId !=
                                                            profile.uid) {
                                                      _showProfile(profile.uid);
                                                    }
                                                  },
                                                  child: Text(
                                                    profile?.displayName ??
                                                        "Ẩn danh",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "${checkin.createdAt.day}/${checkin.createdAt.month}/${checkin.createdAt.year}",
                                                style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (checkin.images.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(
                                            checkin.images.first,
                                            width: double.infinity,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (category != null)
                                      Flexible(
                                        child: Chip(
                                          label: Text(category.name,
                                              overflow: TextOverflow.ellipsis),
                                          avatar: Image.network(
                                              category.iconUrl,
                                              width: 40,
                                              height: 40),
                                        ),
                                      ),
                                    if (vibe != null) ...[
                                      const SizedBox(width: 6),
                                      Chip(
                                        label: Text(vibe.name,
                                            overflow: TextOverflow.ellipsis),
                                        avatar: Text(checkin.vibeIcon,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                    const Spacer(),
                                    Obx(() {
                                      return Row(
                                        children: [
                                          Icon(Icons.thumb_up,
                                              size: 18,
                                              color: clickLikeController
                                                      .isLiked.value
                                                  ? Colors.blue
                                                  : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                              formatCountAdvanced(
                                                  clickLikeController
                                                      .likesCount.value),
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          const SizedBox(width: 12),
                                          Icon(Icons.thumb_down,
                                              size: 18,
                                              color: clickLikeController
                                                      .isDisliked.value
                                                  ? Colors.red
                                                  : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                              formatCountAdvanced(
                                                  clickLikeController
                                                      .dislikesCount.value),
                                              style: const TextStyle(
                                                  fontSize: 13)),
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
      ),
    );
  }
}
