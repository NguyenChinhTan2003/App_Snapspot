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
  var isLoading = true.obs;
  var selectedCheckin = Rxn<CheckInModel>();
  var selectedAddress = "".obs;
  var isAddressLoading = false.obs;
  var addresses = <String, String>{}.obs;

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
      }
    });

    // Load check-ins nếu user đã login
    if (userId != null) {
      fetchCheckIns();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchCheckIns() async {
    if (userId == null) return;

    try {
      isLoading.value = true;
      final checkinsData = await _repository.getUserCheckIns(userId!);
      checkins.value = checkinsData;

      // Lấy địa chỉ cho từng checkin
      for (var c in checkinsData) {
        _fetchAddressForCheckin(c);
      }
    } catch (e) {
      debugPrint("Error fetching check-ins: $e");
    } finally {
      isLoading.value = false;
    }
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

  Future<void> updateCheckIn(String checkInId, String newContent) async {
    try {
      await _repository.updateCheckIn(checkInId, {"content": newContent});
      final index = checkins.indexWhere((c) => c.id == checkInId);
      if (index != -1) {
        final updated = checkins[index];
        checkins[index] = CheckInModel(
          id: updated.id,
          userId: updated.userId,
          spotId: updated.spotId,
          name: updated.name,
          content: newContent,
          categoryId: updated.categoryId,
          categoryIcon: updated.categoryIcon,
          vibeId: updated.vibeId,
          vibeIcon: updated.vibeIcon,
          latitude: updated.latitude,
          longitude: updated.longitude,
          images: updated.images,
          createdAt: updated.createdAt,
          category: updated.category,
          likesCount: updated.likesCount,
          dislikesCount: updated.dislikesCount,
        );
        checkins.refresh();
      }
      Get.snackbar("Thành công", "Đã cập nhật check-in");
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể cập nhật check-in");
    }
  }
}
