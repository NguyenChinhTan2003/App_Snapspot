import 'package:get/get.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/domains/repositories/profile_repository.dart';

class CheckInDetailController extends GetxController {
  final String userId;
  final ProfileRepository _repo = ProfileRepository();

  var user = Rxn<ProfileModel>();
  var isLoading = true.obs;
  var error = RxnString();

  CheckInDetailController(this.userId);

  @override
  void onInit() {
    super.onInit();
    fetchUser();
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
}
