import 'dart:io';
import 'package:app_snapspot/core/common_widgets/custom_image_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/presentations/checkin/controllers/checkin_controller.dart';

class CheckinView extends GetView<CheckinController> {
  const CheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check-in địa điểm"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên địa điểm
              const Text("Tên địa điểm",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: controller.spotNameController,
                decoration: InputDecoration(
                  hintText: "Nhập tên địa điểm bạn đang check-in",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\p{L}0-9\s]', unicode: true)),
                ],
              ),
              const SizedBox(height: 10),
              // Vị trí
              Text("📍 Vị trí: ${controller.locationName.value}",
                  style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 20),

              // Chọn Category
              const Text("Danh mục",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: controller.categories.map((cat) {
                  final isSelected =
                      controller.selectedCategory.value?.id == cat.id;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (_) => controller.selectCategory(cat),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Chọn Vibe
              const Text("Tâm trạng / vibe",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: controller.vibes.map((vibe) {
                  final isSelected =
                      controller.selectedVibe.value?.id == vibe.id;
                  return ChoiceChip(
                    label: Text(vibe.name),
                    selected: isSelected,
                    onSelected: (_) => controller.selectVibe(vibe),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Nội dung
              const Text("Chia sẻ cảm nghĩ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: controller.contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Hôm nay bạn cảm thấy thế nào ở đây?",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              // Ảnh
              const Text("Hình ảnh",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      ...controller.images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(file,
                                  width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => controller.removeImage(index),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: () {
                          Get.bottomSheet(
                            CustomImagePickerSheet(
                              multiSelect: true,
                              onConfirm: (files) {
                                if (files != null && files.isNotEmpty) {
                                  controller.addImages(files);
                                }
                              },
                            ),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_a_photo,
                              size: 30, color: Colors.grey),
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.submitCheckIn,
                  icon: const Icon(Icons.check),
                  label: const Text("Đăng Check-in"),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
