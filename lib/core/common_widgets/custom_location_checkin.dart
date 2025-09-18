import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/core/common_widgets/custom_detail_checkin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model để lưu thông tin đầy đủ của check-in
class EnhancedCheckInModel {
  final CheckInModel checkIn;
  final ProfileModel? profile;
  final CategoryModel? category;
  final VibeModel? vibe;

  EnhancedCheckInModel({
    required this.checkIn,
    this.profile,
    this.category,
    this.vibe,
  });
}

class LocationCheckInsBottomSheet extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? locationName;

  const LocationCheckInsBottomSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 0.5,
    this.locationName,
  });

  @override
  State<LocationCheckInsBottomSheet> createState() =>
      _LocationCheckInsBottomSheetState();
}

class _LocationCheckInsBottomSheetState
    extends State<LocationCheckInsBottomSheet> {
  final CheckInRepository _repository = CheckInRepository();
  List<EnhancedCheckInModel> _enhancedCheckins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Tính toán bounds
      final double kmToDegree = widget.radiusKm / 111.0;
      final double minLat = widget.latitude - kmToDegree;
      final double maxLat = widget.latitude + kmToDegree;
      final double minLng = widget.longitude - kmToDegree;
      final double maxLng = widget.longitude + kmToDegree;

      // Lấy check-ins
      final checkinsData =
          await _repository.getMarkerByBounds(minLat, minLng, maxLat, maxLng);
      final checkins =
          checkinsData.map((data) => CheckInModel.fromJson(data)).toList();
      checkins.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Load thêm thông tin cho mỗi check-in
      final List<EnhancedCheckInModel> enhancedList = [];

      for (final checkin in checkins) {
        // Load profile
        ProfileModel? profile;
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(checkin.userId)
              .get();

          if (profileDoc.exists) {
            debugPrint(
                "✅ Profile data for ${checkin.userId}: ${profileDoc.data()}");
            profile = ProfileModel.fromJson(profileDoc.data()!);
          } else {
            debugPrint("⚠️ Profile not found for ${checkin.userId}");
          }
        } catch (e, st) {
          debugPrint("❌ Error loading profile for ${checkin.userId}: $e");
          debugPrint("StackTrace: $st");
        }

        // Load category
        CategoryModel? category;
        try {
          final categoryDoc = await FirebaseFirestore.instance
              .collection('categories')
              .doc(checkin.categoryId)
              .get();
          if (categoryDoc.exists) {
            category = CategoryModel.fromJson(categoryDoc.data()!);
          }
        } catch (e) {
          debugPrint("❌ Error loading category ${checkin.categoryId}: $e");
        }

        // Load vibe
        VibeModel? vibe;
        try {
          final vibeDoc = await FirebaseFirestore.instance
              .collection('vibe')
              .doc(checkin.vibeId)
              .get();
          if (vibeDoc.exists) {
            vibe = VibeModel.fromJson(vibeDoc.data()!);
          }
        } catch (e) {
          debugPrint("❌ Error loading vibe ${checkin.vibeId}: $e");
        }

        enhancedList.add(EnhancedCheckInModel(
          checkIn: checkin,
          profile: profile,
          category: category,
          vibe: vibe,
        ));
      }

      setState(() {
        _enhancedCheckins = enhancedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCheckInDetail(CheckInModel checkin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckInBottomSheet(checkin: checkin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.locationName ?? "Vị trí này",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (!_isLoading && _error == null)
                  Text(
                    "${_enhancedCheckins.length} bài đăng",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Có lỗi xảy ra",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCheckIns,
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (_enhancedCheckins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Chưa có bài đăng nào",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Hãy là người đầu tiên check-in tại đây!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCheckIns,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _enhancedCheckins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _EnhancedCheckInCard(
          enhancedCheckIn: _enhancedCheckins[index],
          onTap: () => _showCheckInDetail(_enhancedCheckins[index].checkIn),
        ),
      ),
    );
  }
}

class _EnhancedCheckInCard extends StatelessWidget {
  final EnhancedCheckInModel enhancedCheckIn;
  final VoidCallback onTap;

  const _EnhancedCheckInCard({
    required this.enhancedCheckIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final checkin = enhancedCheckIn.checkIn;
    final profile = enhancedCheckIn.profile;
    final category = enhancedCheckIn.category;
    final vibe = enhancedCheckIn.vibe;
    final formattedDate =
        DateFormat('dd/MM/yyyy • HH:mm').format(checkin.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với avatar và thông tin user
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: profile?.photoUrl != null &&
                            profile!.photoUrl!.isNotEmpty
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child:
                        profile?.photoUrl == null || profile!.photoUrl!.isEmpty
                            ? Text(
                                profile?.displayName.isNotEmpty == true
                                    ? profile!.displayName[0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                  ),
                  const SizedBox(width: 12),

                  // Thông tin user
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? "Người dùng ẩn danh",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          formattedDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ảnh chính (nếu có)
              if (checkin.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    checkin.images.first,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 12),

              // Category và Vibe với tên đầy đủ
              Row(
                children: [
                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          checkin.categoryIcon,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 20, color: Colors.grey),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category?.name ?? checkin.categoryId,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Vibe
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          checkin.vibeIcon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vibe?.name ?? checkin.vibeId,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Nội dung bài đăng
              if (checkin.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  checkin.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 8),

              // Footer với số ảnh
              if (checkin.images.length > 1)
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${checkin.images.length} ảnh",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
