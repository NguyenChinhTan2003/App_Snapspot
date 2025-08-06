import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:image_picker/image_picker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CheckinController extends GetxController {
  final RxList<File> images = <File>[].obs;

  final categories = ['Cà phê', 'Ăn uống', 'Chụp ảnh', 'Du lịch'];
  final vibes = ['Chill', 'Bức xúc', 'Vui', 'Yêu'];

  final selectedCategory = RxnString();
  final selectedVibe = RxnString();
  final contentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  late double latitude;
  late double longitude;

   @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;

    if (args != null && args.containsKey('coordinates')) {
      final Point? point = args['coordinates']; // Thêm ? để cho phép giá trị null
      if (point != null && point.coordinates != null) {
        latitude = point.coordinates.lat.toDouble();
        longitude = point.coordinates.lng.toDouble();
      } else {
        // Xử lý trường hợp point hoặc point.coordinates là null
        debugPrint("❌ Lỗi: point hoặc point.coordinates là null");
        // Có thể đặt giá trị mặc định hoặc hiển thị thông báo lỗi cho người dùng
        latitude = 0.0; // Giá trị mặc định
        longitude = 0.0; // Giá trị mặc định
        Get.snackbar("Lỗi", "Không thể lấy tọa độ. Vui lòng thử lại.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } else {
      // Xử lý trường hợp args là null hoặc không chứa 'coordinates'
      debugPrint("❌ Lỗi: Không tìm thấy tọa độ trong arguments");
      latitude = 0.0;
      longitude = 0.0;
      Get.snackbar("Lỗi", "Không tìm thấy tọa độ. Vui lòng thử lại.", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      images.addAll(picked.map((x) => File(x.path)));
    }
  }

  Future<void> pickCamera() async {
    final picked = await _picker.pickImage(source: img_picker.ImageSource.camera);
    if (picked != null) {
      images.add(File(picked.path));
    }
  }

  void submit() {
    // TODO: Gửi dữ liệu lên server hoặc lưu local
    Get.snackbar(
      "✅ Đăng thành công",
      "Địa điểm của bạn đã được lưu!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
