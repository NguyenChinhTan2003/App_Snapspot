import 'dart:typed_data';
import 'package:app_snapspot/presentations/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class CustomImagePickerFullSheet extends StatefulWidget {
  final ProfileController controller;

  const CustomImagePickerFullSheet({super.key, required this.controller});

  @override
  State<CustomImagePickerFullSheet> createState() =>
      _CustomImagePickerFullSheetState();
}

class _CustomImagePickerFullSheetState
    extends State<CustomImagePickerFullSheet> {
  List<AssetEntity> _media = [];

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
        final media = await recent.getAssetListPaged(page: 0, size: 60);
        setState(() => _media = media);
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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

          // title
          const Text(
            "Chọn ảnh đại diện",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // 2 action: camera + album
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAction(
                icon: Icons.camera_alt,
                label: "Chụp ảnh",
                onTap: () {
                  Get.back();
                  widget.controller.pickAndUploadAvatar(fromCamera: true);
                },
              ),
              _buildAction(
                icon: Icons.photo_library,
                label: "Album",
                onTap: () {
                  // scroll lên đầu grid hoặc load lại gallery
                  _loadGallery();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

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
                      return FutureBuilder<Uint8List?>(
                        future: _media[i]
                            .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                        builder: (_, snapshot) {
                          final bytes = snapshot.data;
                          if (bytes == null) {
                            return Container(color: Colors.grey[300]);
                          }
                          return GestureDetector(
                            onTap: () async {
                              final file = await _media[i].file;
                              if (file != null) {
                                Get.back(); // đóng sheet
                                widget.controller.uploadAvatarFromFile(file);
                              }
                            },
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, size: 26, color: Colors.blue),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
