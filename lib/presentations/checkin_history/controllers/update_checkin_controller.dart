import 'dart:io';
import 'dart:typed_data';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/vibe_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension on File {
  Future<List<int>> toBytes() async => await readAsBytes();
}

class UpdateCheckinController extends GetxController {
  final CheckInRepository _checkinRepo = CheckInRepository();
  final VibeRepository _vibeRepo = VibeRepository();

  final CheckInModel checkin;

  UpdateCheckinController(this.checkin);

  final nameController = TextEditingController();
  final contentController = TextEditingController();
  var selectedVibe = Rx<VibeModel?>(null);

  var vibes = <VibeModel>[].obs;

  final RxList<File> newImages = <File>[].obs;
  final RxList<String> oldImages = <String>[].obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();

    // fill data từ checkin
    nameController.text = checkin.name;
    contentController.text = checkin.content;
    oldImages.assignAll(checkin.images);
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      vibes.value = await _vibeRepo.getVibes();
      selectedVibe.value =
          vibes.firstWhereOrNull((v) => v.id == checkin.vibeId);
    } catch (e) {
      debugPrint("Error loading vibes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectVibe(VibeModel vibe) {
    selectedVibe.value = vibe;
  }

  void addImages(List<File> files) {
    newImages.addAll(files);
  }

  void removeNewImage(int index) {
    newImages.removeAt(index);
  }

  void removeOldImage(int index) {
    oldImages.removeAt(index);
  }

  Future<bool> updateCheckin() async {
    if (selectedVibe.value == null) {
      Get.snackbar("Lỗi", "Vui lòng chọn vibe");
      return false;
    }

    try {
      isLoading.value = true;

      // Base update data
      final Map<String, dynamic> updateData = {
        "name": nameController.text,
        "content": contentController.text,
        "vibeId": selectedVibe.value!.id,
        "vibeIcon": selectedVibe.value!.icon,
        "vibeName": selectedVibe.value!.name,
      };

      // ảnh mới thì upload trước
      List<String> newUrls = [];
      if (newImages.isNotEmpty) {
        newUrls =
            await Future.wait(newImages.asMap().entries.map((entry) async {
          final i = entry.key;
          final file = entry.value;
          final fileName = "update_img_$i.jpg";
          final uint8list = Uint8List.fromList(await file.toBytes());
          return await _checkinRepo.uploadImage(
            checkin.userId,
            checkin.id,
            fileName,
            uint8list,
          );
        }));
      }

      // Tổng hợp ảnh
      final allImages = [...oldImages, ...newUrls];
      updateData["images"] = allImages;

      // Update duy nhất 1 lần
      await _checkinRepo.updateCheckIn(checkin.id, updateData);

      Get.back(result: true);
      return true;
    } catch (e) {
      debugPrint("❌ Error in updateCheckin: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
