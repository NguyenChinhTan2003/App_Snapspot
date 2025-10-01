import 'package:get/get.dart';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/domains/repositories/category_repository.dart';

class SearchFilterController extends GetxController {
  final CategoryRepository categoryRepo;

  SearchFilterController(this.categoryRepo);

  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = RxnString();
  var searchQuery = "".obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final result = await categoryRepo.getCategories();
      categories.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCategory(String categoryId) {
    if (selectedCategoryId.value == categoryId) {
      selectedCategoryId.value = null;
    } else {
      selectedCategoryId.value = categoryId;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }
}
