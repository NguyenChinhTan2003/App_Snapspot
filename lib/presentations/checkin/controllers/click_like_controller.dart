import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';

class ClickLikeController extends GetxController {
  final CheckInRepository repo;
  final CheckInModel checkin;
  final String? currentUserId;

  var likesCount = 0.obs;
  var dislikesCount = 0.obs;
  var isLiked = false.obs;
  var isDisliked = false.obs;

  ClickLikeController({
    required this.repo,
    required this.checkin,
    required this.currentUserId,
  });

  @override
  void onInit() {
    super.onInit();
    // Load ban đầu từ model
    likesCount.value = checkin.likesCount;
    dislikesCount.value = checkin.dislikesCount;

    // Đồng bộ trạng thái reaction của current user
    if (currentUserId != null) {
      _loadUserReaction();
    }
  }

  /// Lấy reaction của currentUser trong checkin này
  Future<void> _loadUserReaction() async {
    final reaction = await repo.getUserReaction(checkin.id, currentUserId!);
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
  }

  Future<void> toggleLike() async {
    if (currentUserId == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để Like");
      return;
    }

    final result =
        await repo.toggleReaction(checkin.id, currentUserId!, 'like');

    likesCount.value = result['likesCount'];
    dislikesCount.value = result['dislikesCount'];
    isLiked.value = result['isLiked'];
    isDisliked.value = result['isDisliked'];
  }

  Future<void> toggleDislike() async {
    if (currentUserId == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để Dislike");
      return;
    }

    final result =
        await repo.toggleReaction(checkin.id, currentUserId!, 'dislike');

    likesCount.value = result['likesCount'];
    dislikesCount.value = result['dislikesCount'];
    isLiked.value = result['isLiked'];
    isDisliked.value = result['isDisliked'];
  }
}
