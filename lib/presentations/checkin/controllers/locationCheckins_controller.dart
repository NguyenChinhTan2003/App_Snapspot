// ignore: file_names
import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum CheckInSortOption { newest, oldest, mostLiked, mostDisliked }

enum CheckInTimeOption { all, last7Days, last30Days }

enum CheckInVibeOption { all, thugian, vuive, yeuduong, bucxuc }

class LocationCheckInsController extends GetxController {
  final CheckInRepository repo;
  final String spotId;
  final String? currentUserId;

  LocationCheckInsController(this.repo, this.spotId, this.currentUserId);

  var isLoading = true.obs;
  var error = RxnString();

  var allCheckins = <EnhancedCheckInModel>[];
  var checkins = <EnhancedCheckInModel>[].obs;

  var sortOption = CheckInSortOption.newest.obs;
  var timeOption = CheckInTimeOption.all.obs;
  var vibeOption = CheckInVibeOption.all.obs;

  void setSort(CheckInSortOption opt) {
    sortOption.value = opt;
    applyFilters();
  }

  void setTime(CheckInTimeOption opt) {
    timeOption.value = opt;
    applyFilters();
  }

  void setVibe(CheckInVibeOption opt) {
    vibeOption.value = opt;
    applyFilters();
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint(
        "LocationCheckInsController created: spotId=$spotId, currentUserId=$currentUserId");
    fetchCheckIns();
  }

  Future<void> fetchCheckIns() async {
    try {
      isLoading.value = true;
      error.value = null;

      final data = await repo.getCheckInsBySpot(spotId);
      allCheckins = data;
      applyFilters();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// map enum vibe id trong Firestore
  String mapVibeEnum(CheckInVibeOption opt) {
    switch (opt) {
      case CheckInVibeOption.thugian:
        return "thugian";
      case CheckInVibeOption.vuive:
        return "vuive";
      case CheckInVibeOption.yeuduong:
        return "yeuduong";
      case CheckInVibeOption.bucxuc:
        return "bucxuc";
      default:
        return "";
    }
  }

  void applyFilters() {
    var filtered = List<EnhancedCheckInModel>.from(allCheckins);

    // Filter theo thời gian
    final now = DateTime.now();
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

    // Filter theo vibe
    if (vibeOption.value != CheckInVibeOption.all) {
      final targetVibeId = mapVibeEnum(vibeOption.value);
      filtered = filtered.where((c) {
        final vibeId = c.vibe?.id.toLowerCase() ?? "";
        return vibeId == targetVibeId;
      }).toList();
    }

    // Sort
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

    checkins.assignAll(filtered);
  }
}
