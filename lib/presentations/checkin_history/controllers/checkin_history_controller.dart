import 'package:app_snapspot/applications/services/mapbox_service.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';

class CheckInHistoryController extends GetxController {
  final CheckInRepository _repository = CheckInRepository();
  late final CheckInModel checkin;

  var checkins = <CheckInModel>[].obs;
  var filteredCheckins = <CheckInModel>[].obs;
  var isLoading = true.obs;
  var selectedCheckin = Rxn<CheckInModel>();
  var selectedAddress = "".obs;
  var isAddressLoading = false.obs;
  var addresses = <String, String>{}.obs;
  var searchQuery = "".obs;

  AuthController get _authController => Get.find<AuthController>();
  String? get userId => _authController.firebaseUser.value?.uid;

  @override
  void onInit() {
    super.onInit();

    // Lắng nghe user login/logout để tự load lại check-in
    ever(_authController.firebaseUser, (_) {
      if (userId != null) {
        fetchCheckIns();
      } else {
        checkins.clear();
        filteredCheckins.clear();
      }
    });

    // Load check-ins nếu user đã login
    if (userId != null) {
      fetchCheckIns();
    } else {
      isLoading.value = false;
    }
    ever(searchQuery, (_) => _applyFilter());
  }

  Future<void> refreshAfterUpdate() async {
    await fetchCheckIns();
  }

  Future<void> fetchCheckIns() async {
    if (userId == null) return;

    try {
      isLoading.value = true;
      final checkinsData = await _repository.getUserCheckIns(userId!);
      checkins.value = checkinsData;
      filteredCheckins.assignAll(checkinsData);

      for (var c in checkinsData) {
        _fetchAddressForCheckin(c);
      }
    } catch (e) {
      debugPrint("Error fetching check-ins: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter() {
    final query = searchQuery.value.trim().toLowerCase();

    if (query.isEmpty) {
      filteredCheckins.assignAll(checkins);
    } else {
      filteredCheckins.assignAll(
        checkins.where((c) {
          final name = (c.name ?? "").trim().toLowerCase();
          return name == query;
        }).toList(),
      );
    }
  }

  void updateSearchQuery(String query) {
    debugPrint("Search query: $query");
    searchQuery.value = query.trim();
  }

  Future<void> _fetchAddressForCheckin(CheckInModel checkin) async {
    try {
      final address =
          await MapboxService.getPlaceName(checkin.latitude, checkin.longitude);
      addresses[checkin.id] = address;
    } catch (e) {
      addresses[checkin.id] = "Không tìm thấy địa chỉ";
    }
  }

  Future<void> deleteCheckIn(String checkInId) async {
    try {
      // Tìm checkin để lấy spotId
      final checkinToDelete = checkins.firstWhere((c) => c.id == checkInId);

      await _repository.deleteCheckIn(
        checkInId,
        userId!,
        checkinToDelete.spotId,
      );

      checkins.removeWhere((c) => c.id == checkInId);

      Get.snackbar("Thành công", "Đã xóa check-in");
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể xóa check-in");
    }
  }
}
