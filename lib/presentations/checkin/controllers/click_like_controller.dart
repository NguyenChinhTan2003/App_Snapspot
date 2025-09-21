import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';

class ClickLikeController extends GetxController {
  final CheckInRepository repo;
  final CheckInModel checkin;
  final String? currentUserId;

  var likes = <String>[].obs;
  var dislikes = <String>[].obs;

  ClickLikeController({
    required this.repo,
    required this.checkin,
    required this.currentUserId,
  });

  @override
  void onInit() {
    super.onInit();
    likes.assignAll(checkin.likes ?? []);
    dislikes.assignAll(checkin.dislikes ?? []);
  }

  bool get isLiked => currentUserId != null && likes.contains(currentUserId);
  bool get isDisliked =>
      currentUserId != null && dislikes.contains(currentUserId);

  Future<void> toggleLike() async {
    if (currentUserId == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để Like");
      return;
    }

    await repo.toggleLike(checkin.id, currentUserId!);
    // cập nhật state local cho mượt
    if (isLiked) {
      likes.remove(currentUserId);
    } else {
      likes.add(currentUserId!);
      dislikes.remove(currentUserId);
    }
  }

  Future<void> toggleDislike() async {
    if (currentUserId == null) {
      Get.snackbar("Thông báo", "Bạn cần đăng nhập để Dislike");
      return;
    }

    await repo.toggleDislike(checkin.id, currentUserId!);
    // cập nhật state local cho mượt
    if (isDisliked) {
      dislikes.remove(currentUserId);
    } else {
      dislikes.add(currentUserId!);
      likes.remove(currentUserId);
    }
  }
}
