import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/vibe_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum CheckInSortOption { newest, oldest, mostLiked, mostDisliked }

enum CheckInTimeOption { all, last7Days, last30Days }

class LocationCheckInsController extends GetxController {
  final CheckInRepository repo;
  final String spotId;
  final String? currentUserId;

  LocationCheckInsController(this.repo, this.spotId, this.currentUserId);

  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var error = RxnString();

  var allCheckins = <EnhancedCheckInModel>[]; // cache tất cả check-in
  var displayedCheckins = <EnhancedCheckInModel>[].obs; // check-in hiển thị

  var vibes = <VibeModel>[].obs;
  var selectedVibeId = RxnString();

  var sortOption = CheckInSortOption.newest.obs;
  var timeOption = CheckInTimeOption.all.obs;

  int page = 0;
  final int pageSize = 10;

  @override
  void onInit() {
    super.onInit();
    fetchVibes();
    fetchCheckIns();
  }

  Future<void> fetchVibes() async {
    try {
      final data = await VibeRepository().getAllVibes();
      vibes.assignAll(data);
    } catch (e) {
      debugPrint("Error fetching vibes: $e");
    }
  }

  /// Fetch tất cả check-in từ repo
  Future<void> fetchCheckIns() async {
    try {
      isLoading.value = true;
      error.value = null;

      final data = await repo.getCheckInsBySpot(spotId);
      allCheckins = data;
      page = 0;
      displayedCheckins.clear();
      loadNextPage();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load trang tiếp theo
  void loadNextPage() {
    if (isLoadingMore.value) return;

    isLoadingMore.value = true;

    final filtered = _applyFilters(allCheckins);

    final start = page * pageSize;
    if (start >= filtered.length) {
      isLoadingMore.value = false;
      return; // hết dữ liệu
    }

    final end = (start + pageSize).clamp(0, filtered.length);
    displayedCheckins.addAll(filtered.sublist(start, end));
    page++;
    isLoadingMore.value = false;
  }

  /// Apply filter nhưng chưa slice paging
  List<EnhancedCheckInModel> _applyFilters(List<EnhancedCheckInModel> list) {
    final now = DateTime.now();
    var filtered = List<EnhancedCheckInModel>.from(list);

    // filter time
    filtered = filtered.where((c) {
      final createdAt = c.checkIn.createdAt;
      switch (timeOption.value) {
        case CheckInTimeOption.last7Days:
          return createdAt.isAfter(now.subtract(const Duration(days: 7)));
        case CheckInTimeOption.last30Days:
          return createdAt.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();

    // filter vibe
    filtered = filtered.where((c) {
      if (selectedVibeId.value == null) return true;
      final vibeId = c.vibe?.id;
      if (vibeId == null || vibeId.isEmpty) return false;
      return vibeId == selectedVibeId.value;
    }).toList();

    // sort
    switch (sortOption.value) {
      case CheckInSortOption.newest:
        filtered
            .sort((a, b) => b.checkIn.createdAt.compareTo(a.checkIn.createdAt));
        break;
      case CheckInSortOption.oldest:
        filtered
            .sort((a, b) => a.checkIn.createdAt.compareTo(b.checkIn.createdAt));
        break;
      case CheckInSortOption.mostLiked:
        filtered.sort(
            (a, b) => b.checkIn.likesCount.compareTo(a.checkIn.likesCount));
        break;
      case CheckInSortOption.mostDisliked:
        filtered.sort((a, b) =>
            b.checkIn.dislikesCount.compareTo(a.checkIn.dislikesCount));
        break;
    }

    return filtered;
  }

  // Khi filter mới
  void applyFilters() {
    page = 0;
    displayedCheckins.clear();
    loadNextPage();
  }

  void setSort(CheckInSortOption opt) {
    sortOption.value = opt;
    applyFilters();
  }

  void setTime(CheckInTimeOption opt) {
    timeOption.value = opt;
    applyFilters();
  }

  void setVibe(String? vibeId) {
    selectedVibeId.value = (vibeId == 'all') ? null : vibeId;
    applyFilters();
  }
}
