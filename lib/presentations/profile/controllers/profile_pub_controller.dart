import 'package:get/get.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/domains/repositories/profile_repository.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';

class ProfilePubController extends GetxController {
  final String uid;
  final _profileRepo = ProfileRepository();
  final _checkInRepo = CheckInRepository();

  var isLoading = true.obs;
  var profile = Rx<ProfileModel?>(null);
  var totalCheckIns = 0.obs;
  var totalLikes = 0.obs;
  var totalDislikes = 0.obs;

  ProfilePubController(this.uid);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;

    final p = await _profileRepo.getProfile(uid);
    profile.value = p;

    final checkins = await _checkInRepo.getUserCheckIns(uid);
    totalCheckIns.value = checkins.length;

    int likes = 0;
    int dislikes = 0;
    for (final c in checkins) {
      likes += c.likesCount;
      dislikes += c.dislikesCount;
    }
    totalLikes.value = likes;
    totalDislikes.value = dislikes;

    isLoading.value = false;
  }
}
