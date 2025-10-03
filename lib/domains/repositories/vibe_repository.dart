import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';

class VibeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<VibeModel>> getVibes() async {
    final snapshot = await _db.collection("vibe").get();

    return snapshot.docs.map((doc) => VibeModel.fromJson(doc.data())).toList();
  }

  Future<List<VibeModel>> getAllVibes() async {
    final snapshot = await _db.collection("vibe").orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return VibeModel.fromJson(data);
    }).toList();
  }
}
