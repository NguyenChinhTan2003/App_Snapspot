import 'dart:async';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/applications/services/mapbox_service.dart';
import 'package:flutter/services.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/domains/repositories/profile_repository.dart';

class CheckInDetailController extends GetxController {
  final String userId;
  final CheckInModel checkin;
  final ProfileRepository _repo = ProfileRepository();
  final CheckInRepository _checkInRepo = CheckInRepository();

  var user = Rxn<ProfileModel>();
  var address = RxString("Đang tải địa chỉ...");
  var isLoading = true.obs;
  var error = RxnString();
  var copied = false.obs;

  StreamSubscription? _checkinSub;

  CheckInDetailController(this.userId, this.checkin);

  @override
  void onInit() {
    super.onInit();
    fetchUser();
    fetchAddress();

    // Lắng nghe checkin realtime để biết khi bị xóa
    _checkinSub = _checkInRepo.streamCheckIn(checkin.id).listen(
      (updated) {
        if (updated == null) {
          // Checkin đã bị xóa -> back
          Future.microtask(() {
            if (Get.isOverlaysOpen) {
              Get.back();
              Get.snackbar("Thông báo", "Checkin đã bị xóa");
            }
          });
        }
      },
      onError: (e) {
        if (e.toString().contains("Checkin not found")) {
          Future.microtask(() {
            if (Get.isOverlaysOpen) {
              Get.back();
              Get.snackbar("Thông báo", "Checkin đã bị xóa");
            }
          });
        }
      },
    );
  }

  Future<void> fetchUser() async {
    try {
      isLoading.value = true;
      final profile = await _repo.getProfile(userId);
      user.value = profile;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAddress() async {
    try {
      final result =
          await MapboxService.getPlaceName(checkin.latitude, checkin.longitude);
      address.value = result;
    } catch (e) {
      address.value = "Lỗi lấy địa chỉ: $e";
    }
  }

  Future<void> copyAddress() async {
    await Clipboard.setData(ClipboardData(text: address.value));
    copied.value = true;

    // tự reset sau 2s
    Future.delayed(const Duration(seconds: 2), () {
      copied.value = false;
    });
  }

  @override
  void onClose() {
    _checkinSub?.cancel();
    super.onClose();
  }
}
