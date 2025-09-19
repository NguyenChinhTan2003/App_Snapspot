import 'dart:io';
import 'dart:typed_data';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/data/models/spot_model.dart';
import 'package:app_snapspot/domains/repositories/checkin_repository.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
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
  final SpotRepository _spotRepo = SpotRepository();

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
      debugPrint("Error loading data: $e");
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

      // Tìm Spot (gần toạ độ)
      SpotModel? spot = await _spotRepo.findSpot(latitude, longitude);

      if (spot!.categoryId != selectedCategory.value!.id) {
        debugPrint("🔹 Spot hiện tại không cùng category, tạo spot mới");
        spot = null;
      } else {
        debugPrint("🔹 Spot found and same category: ${spot?.id}");
      }
      // Nếu chưa có thì tạo Spot mới (tạo SpotModel rồi gọi repo.createSpot)
      if (spot == null) {
        final newSpot = SpotModel(
          id: const Uuid().v4(),
          latitude: latitude,
          longitude: longitude,
          categoryId: selectedCategory.value!.id,
          categoryIcon: selectedCategory.value!.iconUrl,
          name: null, // hoặc truyền tên nếu bạn có
          createdAt: DateTime.now(),
        );

        await _spotRepo.createSpot(newSpot);
        spot = newSpot;
      }

      //Tạo CheckIn
      final checkIn = CheckInModel(
        id: checkInId,
        userId: userId!,
        spotId: spot.id,
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

      // Lưu checkin (repo sẽ thêm field spotId nếu bạn dùng collection "checkins")
      await _checkinRepo.createCheckIn(checkIn, spot.id);

      final result = {
        ...checkIn.toJson(),
        "spotId": spot.id,
      };

      // Quay về màn trước với result
      Get.back(result: result);

      // Upload ảnh song song
      if (images.isNotEmpty) {
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
          await _checkinRepo.updateCheckInImages(checkInId, urls);
          debugPrint("✅ Images uploaded for $checkInId");
        });
      }

      return result;
    } catch (e) {
      debugPrint("❌ Error in submitCheckIn: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
