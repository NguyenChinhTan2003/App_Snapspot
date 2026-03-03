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

  LocationCheckInsController(
    this.repo,
    this.spotId,
    this.currentUserId,
  );

  /// UI states
  var displayedCheckins = <EnhancedCheckInModel>[].obs;
  var vibes = <VibeModel>[].obs;

  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var error = RxnString();

  /// Filters
  var selectedVibeId = RxnString();
  CheckInSortOption sortOption = CheckInSortOption.newest;
  CheckInTimeOption timeOption = CheckInTimeOption.all;

  final int pageSize = 10;

  @override
  void onInit() {
    super.onInit();
    _initLoad();
  }

  Future<void> _initLoad() async {
    isLoading(true);

    await Future.wait([
      fetchVibes(),
      fetchCheckIns(),
    ]);

    isLoading(false);
  }

  Future<void> fetchVibes() async {
    try {
      final data = await VibeRepository().getAllVibes();
      vibes.assignAll(data);
    } catch (e) {
      debugPrint("Error fetching vibes: $e");
    }
  }

  Future<void> fetchCheckIns() async {
    isLoading(true);
    error.value = null;

    try {
      displayedCheckins.clear();
      hasMore(true);
      repo.lastDoc = null; // reset pagination

      await loadNextPage();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMore.value || isLoadingMore.value) return;

    isLoadingMore(true);

    try {
      DateTime? minDate;
      switch (timeOption) {
        case CheckInTimeOption.last7Days:
          minDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case CheckInTimeOption.last30Days:
          minDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          minDate = null;
      }

      final newItems = await repo.getCheckInsFiltered(
        spotId: spotId,
        pageSize: pageSize,
        sortOption: sortOption,
        vibeId: selectedVibeId.value,
        minDate: minDate,
      );

      if (newItems.isEmpty) {
        hasMore(false);
      } else {
        displayedCheckins.addAll(newItems);
        if (newItems.length < pageSize) hasMore(false);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingMore(false);
    }
  }

  void changeSort(CheckInSortOption option) {
    sortOption = option;
    fetchCheckIns();
  }

  void changeTimeFilter(CheckInTimeOption option) {
    timeOption = option;
    fetchCheckIns();
  }

  void selectVibe(String? id) {
    selectedVibeId.value = id;
    fetchCheckIns();
  }
}
