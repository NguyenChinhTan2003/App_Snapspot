import 'package:app_snapspot/presentations/map/controllers/search_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CustomSearchFilterBar extends StatefulWidget {
  final Function(String searchText, String categoryId) onSearch;

  const CustomSearchFilterBar({super.key, required this.onSearch});

  @override
  State<CustomSearchFilterBar> createState() => _CustomSearchFilterBarState();
}

class _CustomSearchFilterBarState extends State<CustomSearchFilterBar> {
  late final TextEditingController _textController;
  final controller = Get.find<SearchFilterController>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: controller.searchQuery.value);

    // Lắng nghe thay đổi searchQuery từ controller để đồng bộ UI
    ever(controller.searchQuery, (String? value) {
      if (value != null && value != _textController.text) {
        _textController.text = value;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              onChanged: (value) {
                controller.updateSearchQuery(value);
                widget.onSearch(
                    value, controller.selectedCategoryId.value ?? '');
              },
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: "Tìm kiếm tên địa điểm",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\p{L}0-9\s]', unicode: true)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Category Chips
          Obx(() {
            if (controller.isLoading.value) {
              return SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
              );
            }

            if (controller.categories.isEmpty) {
              return const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    "Không có danh mục",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = controller.categories[index];

                  return Obx(() {
                    final isSelected =
                        controller.selectedCategoryId.value == cat.id;

                    return GestureDetector(
                      onTap: () {
                        controller.updateCategory(isSelected ? null : cat.id);
                        widget.onSearch(
                          controller.searchQuery.value,
                          controller.selectedCategoryId.value ?? '',
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.green : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                cat.iconUrl,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Icon(
                                    Icons.category,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
