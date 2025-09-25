import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/domains/repositories/category_repository.dart';

class SearchFilterController extends GetxController {
  final CategoryRepository categoryRepo;

  SearchFilterController(this.categoryRepo);

  var searchText = ''.obs;
  var selectedCategory = ''.obs;
  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final list = await categoryRepo.getCategories();
      categories.assignAll(list);
    } catch (e) {
      debugPrint("❌ Error fetching categories: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String categoryId) {
    if (selectedCategory.value == categoryId) {
      selectedCategory.value = ''; // bỏ chọn nếu nhấn lần 2
    } else {
      selectedCategory.value = categoryId;
    }
  }
}
