import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/presentations/auth/controllers/auth_controller.dart';

class ClickLikeController extends GetxController {
  final CheckInModel checkin;
  final CheckInRepository repo = CheckInRepository();

  final currentUserId = RxnString();
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

    // Realtime checkin counts
    _checkinSub = repo.streamCheckIn(checkin.id).listen((updated) {
      if (updated == null) {
        likesCount.value = 0;
        dislikesCount.value = 0;
        Get.snackbar("Thông báo", "Checkin này đã bị xoá");
        return;
      }
      likesCount.value = updated.likesCount;
      dislikesCount.value = updated.dislikesCount;
    });

    // Realtime current user
    final auth = Get.find<AuthController>();
    currentUserId.value = auth.firebaseUser.value?.uid;

    ever<User?>(auth.firebaseUser, (user) {
      final uid = user?.uid;
      if (uid != currentUserId.value) {
        currentUserId.value = uid;
        _reactionSub?.cancel();
        if (uid != null) {
          _bindUserReaction(uid);
        } else {
          isLiked.value = false;
          isDisliked.value = false;
          hasLoadedUserReaction.value = false;
        }
      }
    });

    // Nếu đã login thì bind ngay
    if (currentUserId.value != null) _bindUserReaction(currentUserId.value!);
  }

  void _bindUserReaction(String uid) {
    _reactionSub?.cancel();
    _reactionSub = repo.streamUserReaction(checkin.id, uid).listen((reaction) {
      switch (reaction) {
        case 'like':
          isLiked.value = true;
          isDisliked.value = false;
          break;
        case 'dislike':
          isLiked.value = false;
          isDisliked.value = true;
          break;
        default:
          isLiked.value = false;
          isDisliked.value = false;
      }
      hasLoadedUserReaction.value = true;
    });
  }

  Future<void> toggleReaction(String type) async {
    final uid = currentUserId.value;
    if (uid == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để thực hiện hành động này");
      return;
    }
    await repo.toggleReaction(checkin.id, uid, type);
  }

  @override
  void onClose() {
    _checkinSub?.cancel();
    _reactionSub?.cancel();
    super.onClose();
  }
}
