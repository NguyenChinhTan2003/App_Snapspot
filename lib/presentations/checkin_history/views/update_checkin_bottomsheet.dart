import 'dart:io';
import 'package:app_snapspot/presentations/checkin_history/controllers/update_checkin_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/core/common_widgets/custom_image_picker_sheet.dart';

void showUpdateCheckInSheet(
  CheckInModel checkin, {
  VoidCallback? onUpdated,
}) {
  final updateController = Get.put(UpdateCheckinController(checkin));

  Get.bottomSheet(
    Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Text("Cập nhật Check-in",
                    style: Get.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Tên địa điểm
                TextField(
                  controller: updateController.nameController,
                  decoration: const InputDecoration(
                    labelText: "Tên địa điểm",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Nội dung
                TextField(
                  controller: updateController.contentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Nội dung",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),
                Text("Chọn vibe",
                    style: Get.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 12,
                  children: updateController.vibes.map((v) {
                    final isSelected =
                        updateController.selectedVibe.value?.id == v.id;
                    return ChoiceChip(
                      label: Text("${v.icon} "),
                      selected: isSelected,
                      onSelected: (_) => updateController.selectVibe(v),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                Text("Ảnh",
                    style: Get.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: [
                    // ảnh cũ
                    ...updateController.oldImages.asMap().entries.map((e) {
                      final idx = e.key;
                      final img = e.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(img,
                                width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => updateController.removeOldImage(idx),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // ảnh mới
                    ...updateController.newImages.asMap().entries.map((e) {
                      final idx = e.key;
                      final file = e.value;
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
                              onTap: () => updateController.removeNewImage(idx),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // nút thêm ảnh
                    GestureDetector(
                      onTap: () {
                        Get.bottomSheet(
                          CustomImagePickerSheet(
                            multiSelect: true,
                            onConfirm: (files) {
                              if (files != null && files.isNotEmpty) {
                                updateController.addImages(files);
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
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await updateController.updateCheckin();
                      if (success) {
                        Get.back();
                        Get.snackbar(
                            "Thành công", "Cập nhật checkin thành công");
                        onUpdated?.call();
                      } else {
                        Get.snackbar("Lỗi", "Không thể cập nhật checkin");
                      }
                    },
                    child: const Text("Lưu thay đổi"),
                  ),
                ),
              ],
            ),
          ),
        )),
    isScrollControlled: true,
  );
}
