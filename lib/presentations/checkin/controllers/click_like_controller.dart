import 'dart:async';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';

class ClickLikeController extends GetxController {
  final CheckInModel checkin;
  final String? currentUserId;
  final CheckInRepository repo = CheckInRepository();

  // State
  var likesCount = 0.obs;
  var dislikesCount = 0.obs;
  var isLiked = false.obs;
  var isDisliked = false.obs;
  var hasLoadedUserReaction = false.obs;

  StreamSubscription? _checkinSub;
  StreamSubscription? _reactionSub;

  ClickLikeController(this.checkin, {this.currentUserId});

  @override
  void onInit() {
    super.onInit();

    // Lắng nghe realtime checkin
    _checkinSub = repo.streamCheckIn(checkin.id).listen((updatedCheckin) {
      if (updatedCheckin == null) {
        // Checkin đã bị xóa
        likesCount.value = 0;
        dislikesCount.value = 0;

        //thông báo hoặc tự đóng UI
        Get.snackbar("Thông báo", "Checkin này đã bị xoá");
        return;
      }

      likesCount.value = updatedCheckin.likesCount;
      dislikesCount.value = updatedCheckin.dislikesCount;
    });

    // Lắng nghe realtime reaction của user hiện tại
    if (currentUserId != null) {
      _reactionSub = repo
          .streamUserReaction(checkin.id, currentUserId!)
          .listen((reaction) {
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
  }

  Future<void> toggleReaction(String reactionType) async {
    if (currentUserId == null) return;
    await repo.toggleReaction(checkin.id, currentUserId!, reactionType);
  }

  @override
  void onClose() {
    _checkinSub?.cancel();
    _reactionSub?.cancel();
    super.onClose();
  }
}
