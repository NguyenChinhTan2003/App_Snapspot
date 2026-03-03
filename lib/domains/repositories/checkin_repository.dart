import 'dart:typed_data';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
import 'package:app_snapspot/presentations/checkin/controllers/locationCheckins_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  DocumentSnapshot? lastDoc;

  // Cache read profile/category/vibe
  final Map<String, ProfileModel?> _profileCache = {};
  final Map<String, CategoryModel?> _categoryCache = {};
  final Map<String, VibeModel?> _vibeCache = {};

  /// Tạo checkin mới
  Future<void> createCheckIn(CheckInModel checkIn, String spotId) async {
    final data = checkIn.toJson();
    data["spotId"] = spotId;
    data["likesCount"] = 0;
    data["dislikesCount"] = 0;
    await _db.collection("checkins").doc(checkIn.id).set(data);
  }

  Future<void> deleteCheckInFolder(String userId, String checkInId) async {
    final folderPath = 'checkins/$userId/$checkInId';
    final list =
        await _supabase.storage.from('checkins').list(path: folderPath);

    for (final item in list) {
      if (item.name != null) {
        await _supabase.storage
            .from('checkins')
            .remove(['$folderPath/${item.name}']);
      }
    }
  }

  Future<void> deleteCheckIn(
      String checkinId, String userId, String spotId) async {
    final checkinRef = _db.collection('checkins').doc(checkinId);

    final snapshot = await checkinRef.get();
    if (!snapshot.exists) throw Exception("Checkin không tồn tại");
    if (snapshot['userId'] != userId) {
      throw Exception("Bạn không có quyền xoá checkin này");
    }

    await deleteCheckInFolder(userId, checkinId);

    final reactionsRef = checkinRef.collection('reactions');
    final reactionsSnap = await reactionsRef.get();
    final batch = _db.batch();
    for (final doc in reactionsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(checkinRef);
    await batch.commit();

    final checkinsSnap = await _db
        .collection('checkins')
        .where('spotId', isEqualTo: spotId)
        .limit(1)
        .get();

    if (checkinsSnap.docs.isEmpty) {
      await SpotRepository().deleteSpot(spotId);
    }
  }

  /// Cập nhật checkin
  Future<void> updateCheckIn(
      String checkInId, Map<String, dynamic> updates) async {
    updates["updatedAt"] = FieldValue.serverTimestamp();
    await _db.collection("checkins").doc(checkInId).update(updates);
  }

  Future<String?> getUserReaction(String checkinId, String userId) async {
    final doc = await _db
        .collection('checkins')
        .doc(checkinId)
        .collection('reactions')
        .doc(userId)
        .get();

    if (doc.exists) {
      return doc['type'] as String;
    }
    return null;
  }

  /// Toggle reaction (like/dislike)
  Future<Map<String, dynamic>> toggleReaction(
      String checkinId, String userId, String type) async {
    final checkinRef = _db.collection('checkins').doc(checkinId);
    final reactionRef = checkinRef.collection('reactions').doc(userId);

    return _db.runTransaction((txn) async {
      final snap = await txn.get(checkinRef);
      final react = await txn.get(reactionRef);

      int likes = (snap.data()?["likesCount"] ?? 0) as int;
      int dislikes = (snap.data()?["dislikesCount"] ?? 0) as int;

      String? current = react.exists ? react["type"] as String : null;

      // CASE 1: nhấn lại -> xoá reaction
      if (current == type) {
        txn.delete(reactionRef);
        if (type == "like") likes--;
        if (type == "dislike") dislikes--;

        txn.update(checkinRef, {
          "likesCount": likes,
          "dislikesCount": dislikes,
        });

        return {
          "likesCount": likes,
          "dislikesCount": dislikes,
          "isLiked": false,
          "isDisliked": false,
        };
      }

      // CASE 2: chuyển like <=> dislike
      if (current != null && current != type) {
        if (current == "like") likes--;
        if (current == "dislike") dislikes--;

        if (type == "like") likes++;
        if (type == "dislike") dislikes++;

        txn.set(reactionRef, {
          "type": type,
          "userId": userId,
          "createdAt": FieldValue.serverTimestamp(),
        });

        txn.update(checkinRef, {
          "likesCount": likes,
          "dislikesCount": dislikes,
        });

        return {
          "likesCount": likes,
          "dislikesCount": dislikes,
          "isLiked": type == "like",
          "isDisliked": type == "dislike",
        };
      }

      // CASE 3: chưa từng like/dislike
      if (current == null) {
        if (type == "like") likes++;
        if (type == "dislike") dislikes++;

        txn.set(reactionRef, {
          "type": type,
          "userId": userId,
          "createdAt": FieldValue.serverTimestamp(),
        });

        txn.update(checkinRef, {
          "likesCount": likes,
          "dislikesCount": dislikes,
        });

        return {
          "likesCount": likes,
          "dislikesCount": dislikes,
          "isLiked": type == "like",
          "isDisliked": type == "dislike",
        };
      }

      return {
        "likesCount": likes,
        "dislikesCount": dislikes,
        "isLiked": current == "like",
        "isDisliked": current == "dislike",
      };
    });
  }

  /// Lấy danh sách userId đã like/dislike
  Future<Map<String, List<String>>> getReactions(String checkInId) async {
    final snapshot = await _db
        .collection("checkins")
        .doc(checkInId)
        .collection("reactions")
        .get();

    final likes = <String>[];
    final dislikes = <String>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      if (type == "like") {
        likes.add(doc.id);
      } else if (type == "dislike") {
        dislikes.add(doc.id);
      }
    }

    return {
      "likes": likes,
      "dislikes": dislikes,
    };
  }

  /// Lấy tất cả checkins theo Spot
  Future<List<CheckInModel>> getAllCheckInsBySpot(String spotId) async {
    final snapshot = await _db
        .collection("checkins")
        .where("spotId", isEqualTo: spotId)
        .orderBy("createdAt", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CheckInModel.fromJson(doc.data()))
        .toList();
  }

  /// Lấy checkins trong bounding box (dùng cho Map)
  Future<List<Map<String, dynamic>>> getMarkerByBounds(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    final snapshot = await _db
        .collection("checkins")
        .where("latitude", isGreaterThanOrEqualTo: minLat)
        .where("latitude", isLessThanOrEqualTo: maxLat)
        .get();

    // Firestore chưa hỗ trợ query 2 field song song (lat + lng),
    // nên filter lng bằng code
    return snapshot.docs.map((doc) => doc.data()).where((data) {
      final lng = (data["longitude"] as num).toDouble();
      return lng >= minLng && lng <= maxLng;
    }).toList();
  }

  /// Lấy checkins theo Spot, phân trang
  Future<List<EnhancedCheckInModel>> getCheckInsBySpotPaginated({
    required String spotId,
    int limit = 3,
    DocumentSnapshot? startAfterDoc,
  }) async {
    Query query = _db
        .collection("checkins")
        .where("spotId", isEqualTo: spotId)
        .orderBy("createdAt", descending: true)
        .limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return [];

    lastDoc = snapshot.docs.last;

    final checkins = snapshot.docs.map((doc) {
      return CheckInModel.fromJson({
        "id": doc.id,
        ...?doc.data() as Map<String, dynamic>?,
      });
    }).toList();

    return await _enhanceCheckIns(checkins);
  }

  /// Check-in với profile/category/vibe, dùng cache
  Future<List<EnhancedCheckInModel>> _enhanceCheckIns(
      List<CheckInModel> list) async {
    final List<EnhancedCheckInModel> result = [];

    for (final c in list) {
      // Profile
      if (!_profileCache.containsKey(c.userId)) {
        final doc = await _db.collection("profiles").doc(c.userId).get();
        _profileCache[c.userId] =
            doc.exists ? ProfileModel.fromJson(doc.data()!) : null;
      }

      // Category
      if (!_categoryCache.containsKey(c.categoryId)) {
        final doc = await _db.collection("categories").doc(c.categoryId).get();
        _categoryCache[c.categoryId] =
            doc.exists ? CategoryModel.fromJson(doc.data()!) : null;
      }

      // Vibe
      if (!_vibeCache.containsKey(c.vibeId)) {
        final doc = await _db.collection("vibe").doc(c.vibeId).get();
        _vibeCache[c.vibeId] =
            doc.exists ? VibeModel.fromJson(doc.data()!) : null;
      }

      result.add(EnhancedCheckInModel(
        checkIn: c,
        profile: _profileCache[c.userId],
        category: _categoryCache[c.categoryId],
        vibe: _vibeCache[c.vibeId],
      ));
    }

    return result;
  }

  Future<List<EnhancedCheckInModel>> getCheckInsFiltered({
    required String spotId,
    required int pageSize,
    required CheckInSortOption sortOption,
    String? vibeId,
    DateTime? minDate,
  }) async {
    Query query = _db.collection("checkins").where("spotId", isEqualTo: spotId);

    // Filter vibe
    if (vibeId != null && vibeId.isNotEmpty) {
      query = query.where("vibeId", isEqualTo: vibeId);
    }

    // Filter date
    if (minDate != null) {
      query = query.where("createdAt", isGreaterThanOrEqualTo: minDate);
    }

    // Sort
    switch (sortOption) {
      case CheckInSortOption.newest:
        query = query.orderBy("createdAt", descending: true);
        break;
      case CheckInSortOption.oldest:
        query = query.orderBy("createdAt", descending: false);
        break;
      case CheckInSortOption.mostLiked:
        query = query.orderBy("likesCount", descending: true);
        break;
      case CheckInSortOption.mostDisliked:
        query = query.orderBy("dislikesCount", descending: true);
        break;
    }

    // Pagination
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    query = query.limit(pageSize);

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return [];

    lastDoc = snapshot.docs.last;

    final checkins = snapshot.docs.map((doc) {
      return CheckInModel.fromJson({
        "id": doc.id,
        ...?doc.data() as Map<String, dynamic>?,
      });
    }).toList();

    return await _enhanceCheckIns(checkins);
  }

  /// Upload 1 ảnh checkin lên Supabase Storage
  Future<String> uploadImage(
    String userId,
    String checkInId,
    String fileName,
    Uint8List fileBytes,
  ) async {
    final path = 'checkins/$userId/$checkInId/$fileName';

    // Ghi đè nếu file đã tồn tại
    await _supabase.storage.from('checkins').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Lấy URL công khai
    final url = _supabase.storage.from('checkins').getPublicUrl(path);
    return url;
  }

  /// Cập nhật danh sách ảnh cho checkin trong Firestore
  Future<void> updateCheckInImages(String checkInId, List<String> urls) async {
    await _db.collection('checkins').doc(checkInId).update({
      'images': urls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy toàn bộ checkin của 1 user
  Future<List<CheckInModel>> getUserCheckIns(String userId) async {
    try {
      debugPrint("Query checkins for userId: $userId");

      final snapshot = await _db
          .collection("checkins")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("No checkins found for userId: $userId");
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CheckInModel.fromJson({
          "id": doc.id, // luôn lấy doc.id từ Firestore
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint("❌ Error in getUserCheckIns: $e");
      rethrow;
    }
  }

  /// Lấy chi tiết 1 checkin
  Future<CheckInModel?> getCheckInById(String checkInId) async {
    final snapshot = await _db.collection("checkins").doc(checkInId).get();
    if (!snapshot.exists) return null;
    return CheckInModel.fromJson(snapshot.data()!);
  }

  DocumentReference<Map<String, dynamic>> getCheckinRef(String checkinId) {
    return _db.collection('checkins').doc(checkinId);
  }

  DocumentReference<Map<String, dynamic>> getReactionRef(
      String checkinId, String userId) {
    return getCheckinRef(checkinId).collection('reactions').doc(userId);
  }

  /// Lắng nghe realtime cho checkin
  Stream<CheckInModel?> streamCheckIn(String checkinId) {
    return _db.collection("checkins").doc(checkinId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!..["id"] = doc.id;
      return CheckInModel.fromJson(data);
    });
  }

  /// Lắng nghe realtime reaction của 1 user
  Stream<String?> streamUserReaction(String checkinId, String userId) {
    return _db
        .collection("checkins")
        .doc(checkinId)
        .collection("reactions")
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc['type'] as String : null);
  }
}
