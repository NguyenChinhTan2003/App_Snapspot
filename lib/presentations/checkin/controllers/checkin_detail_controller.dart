import 'package:app_snapspot/applications/services/mapbox_service.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/domains/repositories/profile_repository.dart';

class CheckInDetailController extends GetxController {
  final String userId;
  final CheckInModel checkin;
  final ProfileRepository _repo = ProfileRepository();

  var user = Rxn<ProfileModel>();
  var address = RxString("Đang tải địa chỉ...");
  var isLoading = true.obs;
  var error = RxnString();

  CheckInDetailController(this.userId, this.checkin);

  @override
  void onInit() {
    super.onInit();
    fetchUser();
    fetchAddress();
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
}
