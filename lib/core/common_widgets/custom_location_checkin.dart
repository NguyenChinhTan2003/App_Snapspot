import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_snapspot/data/models/spot_model.dart';
import 'custom_detail_checkin.dart';

class LocationCheckInsBottomSheet extends StatefulWidget {
  final SpotModel spot;
  const LocationCheckInsBottomSheet({super.key, required this.spot});

  @override
  State<LocationCheckInsBottomSheet> createState() =>
      _LocationCheckInsBottomSheetState();
}

class _LocationCheckInsBottomSheetState
    extends State<LocationCheckInsBottomSheet> {
  final CheckInRepository _repo = CheckInRepository();
  List<EnhancedCheckInModel> _enhancedCheckins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkins = await _repo.getCheckInsBySpot(widget.spot.id);
      setState(() {
        _enhancedCheckins = checkins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCheckInDetail(checkin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInBottomSheet(checkin: checkin),
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
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.spot.name ?? "Danh sách Check-in",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),

          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("Lỗi: $_error"));
    if (_enhancedCheckins.isEmpty)
      return const Center(child: Text("Chưa có check-in nào tại Spot này"));

    return RefreshIndicator(
      onRefresh: _loadCheckIns,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _enhancedCheckins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final enhanced = _enhancedCheckins[index];
          final checkin = enhanced.checkIn;
          final profile = enhanced.profile;
          final category = enhanced.category;
          final vibe = enhanced.vibe;
          final formattedDate =
              DateFormat('dd/MM/yyyy • HH:mm').format(checkin.createdAt);

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: profile?.photoUrl != null
                              ? NetworkImage(profile!.photoUrl!)
                              : null,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.displayName ?? "Ẩn danh"),
                              Text(formattedDate,
                                  style: const TextStyle(color: Colors.grey)),
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
                          child: Image.network(checkin.images.first,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover),
                        ),
                      ),
                    if (checkin.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(checkin.content),
                      ),
                    Row(
                      children: [
                        if (category != null)
                          Chip(
                              label: Text(category.name),
                              avatar:
                                  Image.network(category.iconUrl, width: 20)),
                        if (vibe != null)
                          Chip(
                              label: Text(vibe.name),
                              avatar: Text(checkin.vibeIcon,
                                  style: const TextStyle(fontSize: 16))),
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
  }
}
