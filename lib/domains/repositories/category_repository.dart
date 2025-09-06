import 'package:app_snapspot/data/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db.collection("categories").get();

    return snapshot.docs
        .map((doc) => CategoryModel.fromJson(doc.data()))
        .toList();
  }
}


