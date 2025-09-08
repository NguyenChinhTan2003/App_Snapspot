import 'dart:io';
import 'dart:typed_data';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app_snapspot/domains/repositories/category_repository.dart';
import 'package:app_snapspot/domains/repositories/vibe_repository.dart';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:uuid/uuid.dart';

extension on File {
  Future<List<int>> toBytes() async => await readAsBytes();
}

class CheckinController extends GetxController {
  final CheckInRepository _checkinRepo = CheckInRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final VibeRepository _vibeRepo = VibeRepository();

  final RxList<File> images = <File>[].obs;
  final contentController = TextEditingController();

  var categories = <CategoryModel>[].obs;
  var vibes = <VibeModel>[].obs;

  var selectedCategory = Rx<CategoryModel?>(null);
  var selectedVibe = Rx<VibeModel?>(null);

  var isLoading = false.obs;

  final RxString locationName = "".obs;

  late double latitude;
  late double longitude;
  String? userId;

  @override
  void onInit() {
    super.onInit();
    _initLocation();
    loadData();
    _getUser();
  }

  void _initLocation() {
    final args = Get.arguments;
    if (args != null && args.containsKey('coordinates')) {
      final Point? point = args['coordinates'];
      if (point != null && point.coordinates != null) {
        latitude = point.coordinates.lat.toDouble();
        longitude = point.coordinates.lng.toDouble();
        locationName.value =
            "(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})";
      } else {
        latitude = 0.0;
        longitude = 0.0;
        locationName.value = "Không xác định";
        Get.snackbar("Lỗi", "Không thể lấy tọa độ",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } else {
      latitude = 0.0;
      longitude = 0.0;
      locationName.value = "Không xác định";
      Get.snackbar("Lỗi", "Không tìm thấy tọa độ",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _getUser() {
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      categories.value = await _categoryRepo.getCategories();
      vibes.value = await _vibeRepo.getVibes();
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(CategoryModel category) {
    selectedCategory.value = category;
  }

  void selectVibe(VibeModel vibe) {
    selectedVibe.value = vibe;
  }

  void addImages(List<File> files) {
    images.addAll(files);
  }

  void removeImage(int index) {
    images.removeAt(index);
  }

  void resetForm() {
    contentController.clear();
    selectedCategory.value = null;
    selectedVibe.value = null;
    images.clear();
    latitude = 0.0;
    longitude = 0.0;
  }

  Future<Map<String, dynamic>?> submitCheckIn() async {
  if (userId == null) {
    Get.snackbar("Lỗi", "Bạn cần đăng nhập trước khi checkin");
    return null;
  }
  if (selectedCategory.value == null || selectedVibe.value == null) {
    Get.snackbar("Lỗi", "Vui lòng chọn danh mục và vibe");
    return null;
  }

  try {
    isLoading.value = true;
    final checkInId = const Uuid().v4();

    // Tạo check-in  (metadata, images rỗng)
    final checkIn = CheckInModel(
      id: checkInId,
      userId: userId!,
      content: contentController.text,
      categoryId: selectedCategory.value!.id,
      categoryIcon: selectedCategory.value!.iconUrl,
      vibeId: selectedVibe.value!.id,
      vibeIcon: selectedVibe.value!.icon,
      latitude: latitude,
      longitude: longitude,
      images: [], 
      createdAt: DateTime.now(),
    );

    await _checkinRepo.createCheckIn(checkIn);

    // Trả về ngay để UI hiển thị check-in
    final result = checkIn.toJson();
    Get.back(result: result);

    //Upload ảnh song song (ngầm)
    Future.wait(images.asMap().entries.map((entry) async {
      final i = entry.key;
      final file = entry.value;
      final fileName = "img_$i.jpg";
      final uint8list = Uint8List.fromList(await file.toBytes());

      return await _checkinRepo.uploadImage(
        userId!,
        checkInId,
        fileName,
        uint8list,
      );
    })).then((urls) async {
      //Update lại check-in với danh sách ảnh
      await _checkinRepo.updateCheckInImages(checkInId, urls);
      print("✅ Images uploaded and updated for $checkInId");
    });

    return result;
  } catch (e) {
    print("❌ Error: $e");
    return null;
  } finally {
    isLoading.value = false;
  }
}

}
