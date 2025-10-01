import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';

class ClickLikeController extends GetxController {
  final CheckInModel checkin;
  final CheckInRepository repo = CheckInRepository();

  // currentUserId reactive
  final RxnString currentUserId = RxnString();

  // State
  var likesCount = 0.obs;
  var dislikesCount = 0.obs;
  var isLiked = false.obs;
  var isDisliked = false.obs;
  var hasLoadedUserReaction = false.obs;

  StreamSubscription? _checkinSub;
  StreamSubscription? _reactionSub;

  ClickLikeController(this.checkin);

  @override
  void onInit() {
    super.onInit();

    // Lắng nghe realtime checkin
    _checkinSub = repo.streamCheckIn(checkin.id).listen((updatedCheckin) {
      if (updatedCheckin == null) {
        likesCount.value = 0;
        dislikesCount.value = 0;
        Get.snackbar("Thông báo", "Checkin này đã bị xoá");
        return;
      }

      likesCount.value = updatedCheckin.likesCount;
      dislikesCount.value = updatedCheckin.dislikesCount;
    });

    // Lắng nghe AuthController để biết user hiện tại
    final auth = Get.find<AuthController>();
    ever<User?>(auth.firebaseUser, (user) {
      currentUserId.value = user?.uid;
      if (currentUserId.value != null) {
        _reactionSub?.cancel();
        _bindUserReaction(currentUserId.value!);
      } else {
        // Nếu user logout thì reset state
        isLiked.value = false;
        isDisliked.value = false;
        hasLoadedUserReaction.value = false;
        _reactionSub?.cancel();
      }
    });
  }

  void _bindUserReaction(String userId) {
    _reactionSub =
        repo.streamUserReaction(checkin.id, userId).listen((reaction) {
      if (reaction == 'like') {
        isLiked.value = true;
        isDisliked.value = false;
      } else if (reaction == 'dislike') {
        isLiked.value = false;
        isDisliked.value = true;
      } else {
        isLiked.value = false;
        isDisliked.value = false;
      }
      hasLoadedUserReaction.value = true;
    });
  }

  Future<void> toggleReaction(String reactionType) async {
    if (currentUserId.value == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để thực hiện hành động này");
      return;
    }
    await repo.toggleReaction(checkin.id, currentUserId.value!, reactionType);
  }

  @override
  void onClose() {
    _checkinSub?.cancel();
    _reactionSub?.cancel();
    super.onClose();
  }
}
