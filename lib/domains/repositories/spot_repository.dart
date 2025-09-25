import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_snapspot/data/models/spot_model.dart';

class SpotRepository {
  final _db = FirebaseFirestore.instance;

  /// Tạo mới Spot
  Future<void> createSpot(SpotModel spot) async {
    try {
      final data = spot.toJson();
      if (spot.name != null && spot.name!.isNotEmpty) {
        data['keywords'] = _generateKeywords(spot.name!);
      }
      await _db.collection("spots").doc(spot.id).set(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSpotName(String spotId, String name) async {
    await _db.collection("spots").doc(spotId).update({
      "name": name,
    });
  }

  /// Cập nhật Spot
  Future<void> updateSpot(SpotModel spot) async {
    try {
      await _db.collection("spots").doc(spot.id).update(spot.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Xoá Spot
  Future<void> deleteSpot(String spotId) async {
    try {
      await _db.collection("spots").doc(spotId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Tìm Spot gần tọa độ (dùng bounding box nhỏ, ví dụ ±0.0005 ~ 50m)
  Future<SpotModel?> findSpot(double lat, double lng) async {
    try {
      const delta = 0.0005; // khoảng 50m
      final spots = await getSpotsInBoundingBox(
        minLat: lat - delta,
        maxLat: lat + delta,
        minLng: lng - delta,
        maxLng: lng + delta,
      );

      if (spots.isEmpty) return null;

      // Nếu nhiều Spot trong box → chọn cái gần nhất
      spots.sort((a, b) {
        final distA = (a.latitude - lat) * (a.latitude - lat) +
            (a.longitude - lng) * (a.longitude - lng);
        final distB = (b.latitude - lat) * (b.latitude - lat) +
            (b.longitude - lng) * (b.longitude - lng);
        return distA.compareTo(distB);
      });

      return spots.first;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy Spot theo id
  Future<SpotModel?> getSpotById(String spotId) async {
    try {
      final doc = await _db.collection("spots").doc(spotId).get();
      if (!doc.exists) return null;
      return SpotModel.fromJson(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy tất cả Spot
  Future<List<SpotModel>> getAllSpots() async {
    try {
      final snapshot = await _db.collection("spots").get();
      return snapshot.docs
          .map((doc) => SpotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy Spot trong bounding box
  Future<List<SpotModel>> getSpotsInBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      // Firestore chỉ query được 1 field range -> query theo latitude trước
      final snapshot = await _db
          .collection("spots")
          .where("latitude", isGreaterThanOrEqualTo: minLat)
          .where("latitude", isLessThanOrEqualTo: maxLat)
          .get();

      final spots = snapshot.docs
          .map((doc) => SpotModel.fromJson(doc.data()))
          .where((spot) => spot.longitude >= minLng && spot.longitude <= maxLng)
          .toList();

      return spots;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy Spot trong bounding box + filter
  Future<List<SpotModel>> getSpotsInBoundingBoxFiltered({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? category,
    String? searchQuery,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("spots")
        .where("latitude", isGreaterThanOrEqualTo: minLat)
        .where("latitude", isLessThanOrEqualTo: maxLat)
        .get();

    final spots = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SpotModel.fromJson(data);
    }).where((spot) {
      final matchLng = spot.longitude >= minLng && spot.longitude <= maxLng;

      final matchCategory =
          category == null || category.isEmpty || spot.categoryId == category;

      final matchSearch = searchQuery == null ||
          searchQuery.isEmpty ||
          (spot.name?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

      return matchLng && matchCategory && matchSearch;
    }).toList();

    return spots;
  }

  List<String> _generateKeywords(String name) {
    final lower = name.toLowerCase().trim();
    final words = lower.split(RegExp(r"\s+"));
    final keywords = <String>[];

    // mỗi từ
    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    // toàn bộ cụm từ
    for (int i = 1; i <= lower.length; i++) {
      keywords.add(lower.substring(0, i));
    }

    return keywords.toSet().toList();
  }
}
