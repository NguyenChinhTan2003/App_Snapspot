import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

class CustomImagePickerSheet extends StatefulWidget {
  final bool multiSelect;
  final Function(List<File>) onConfirm;

  const CustomImagePickerSheet({
    super.key,
    required this.multiSelect,
    required this.onConfirm,
  });

  @override
  State<CustomImagePickerSheet> createState() => _CustomImagePickerSheetState();
}

class _CustomImagePickerSheetState extends State<CustomImagePickerSheet> {
  List<AssetEntity> _media = [];
  final List<AssetEntity> _selected = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      if (albums.isNotEmpty) {
        final recent = albums.first;
        final media = await recent.getAssetListPaged(page: 0, size: 120);
        setState(() => _media = media);
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final file = File(picked.path);
      widget.onConfirm([file]); // trả ảnh camera ngay
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // title + camera button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.multiSelect ? "Chọn nhiều ảnh" : "Chọn ảnh",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt, color: Colors.blue),
                tooltip: "Chụp ảnh",
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _media.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _media.length,
                    itemBuilder: (_, i) {
                      final asset = _media[i];
                      final isSelected = _selected.contains(asset);

                      return FutureBuilder<Uint8List?>(
                        future: asset.thumbnailDataWithSize(
                            const ThumbnailSize(200, 200)),
                        builder: (_, snapshot) {
                          final bytes = snapshot.data;
                          if (bytes == null) {
                            return Container(color: Colors.grey[300]);
                          }
                          return GestureDetector(
                            onTap: () async {
                              if (widget.multiSelect) {
                                setState(() {
                                  if (isSelected) {
                                    _selected.remove(asset);
                                  } else {
                                    _selected.add(asset);
                                  }
                                });
                              } else {
                                final file = await asset.file;
                                if (file != null) {
                                  widget.onConfirm([file]);
                                  Get.back();
                                }
                              }
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(bytes, fit: BoxFit.cover),
                                if (isSelected)
                                  Container(
                                    color: Colors.black.withOpacity(0.4),
                                    child: const Center(
                                      child: Icon(Icons.check_circle,
                                          color: Colors.white, size: 32),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          if (widget.multiSelect)
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          final files = await Future.wait(
                              _selected.map((e) => e.file).toList());
                          widget.onConfirm(files.whereType<File>().toList());
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? "Chọn ít nhất 1 ảnh"
                        : "Dùng ${_selected.length} ảnh",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
