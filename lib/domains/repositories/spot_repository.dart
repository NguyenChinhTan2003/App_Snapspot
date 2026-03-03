import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_snapspot/data/models/spot_model.dart';

class SpotRepository {
  final _db = FirebaseFirestore.instance;

  /// Tạo mới Spot
  Future<void> createSpot(SpotModel spot) async {
    try {
      final data = spot.toJson();
      if (spot.name != null && spot.name!.isNotEmpty) {
        data['nameLower'] = spot.name!.toLowerCase().trim();
      }
      await _db.collection("spots").doc(spot.id).set(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSpotName(String spotId, String name) async {
    await _db.collection("spots").doc(spotId).update({
      "name": name,
      "nameLower": name.toLowerCase().trim(),
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

  // lấy Spot theo tên
  Future<List<SpotModel>> getSpotsByName(String name) async {
    final query = await _db
        .collection("spots")
        .where("nameLower", isEqualTo: name.toLowerCase().trim())
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SpotModel.fromJson(data);
    }).toList();
  }

  Future<List<SpotModel>> getSpotsByNameNearLocation({
    required String name,
    required double lat,
    required double lng,
    double radiusInKm = 10,
    String? category,
  }) async {
    // Query theo tên
    final query = await _db
        .collection("spots")
        .where("nameLower", isEqualTo: name.toLowerCase().trim())
        .get();

    final spots = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SpotModel.fromJson(data);
    }).toList();

    // Lọc theo bán kính
    final filtered = spots.where((spot) {
      final d = _calculateDistance(
        lat,
        lng,
        spot.latitude,
        spot.longitude,
      );
      return d <= radiusInKm;
    }).toList();

    // Lọc thêm theo category
    final categoryFiltered = filtered.where((spot) {
      return category == null ||
          category.isEmpty ||
          spot.categoryId == category;
    }).toList();

    // Sort theo khoảng cách
    categoryFiltered.sort((a, b) {
      final distA = _calculateDistance(lat, lng, a.latitude, a.longitude);
      final distB = _calculateDistance(lat, lng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return categoryFiltered;
  }

  /// Tính khoảng cách Haversine giữa 2 tọa độ (km)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  /// Lấy Spot trong bounding box + filter
  Future<List<SpotModel>> getSpotsInBoundingBoxFiltered({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? category,
    String? searchQuery,
  }) async {
    final snapshot = await _db
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
}
