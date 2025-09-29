import 'dart:typed_data';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:app_snapspot/domains/repositories/spot_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:flutter/foundation.dart';

class CheckInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Tạo checkin mới
  Future<void> createCheckIn(CheckInModel checkIn, String spotId) async {
    final data = checkIn.toJson();
    data["spotId"] = spotId;
    data["likesCount"] = 0;
    data["dislikesCount"] = 0;
    await _db.collection("checkins").doc(checkIn.id).set(data);
  }

  Future<void> deleteCheckIn(
      String checkinId, String userId, String spotId) async {
    final checkinRef = _db.collection('checkins').doc(checkinId);

    // 1. Lấy dữ liệu checkin để check quyền
    final snapshot = await checkinRef.get();
    if (!snapshot.exists) {
      throw Exception("Checkin không tồn tại");
    }
    final data = snapshot.data()!;
    if (data['userId'] != userId) {
      throw Exception("Bạn không có quyền xoá checkin này");
    }

    // 2. Xoá reactions trước
    final reactionsRef = checkinRef.collection('reactions');
    final reactionsSnap = await reactionsRef.get();
    for (final doc in reactionsSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Xoá checkin
    await checkinRef.delete();

    // 4. Kiểm tra xem spot còn checkin nào không
    final checkinsSnap = await _db
        .collection('checkins')
        .where('spotId', isEqualTo: spotId)
        .limit(1)
        .get();

    if (checkinsSnap.docs.isEmpty) {
      // Không còn checkin nào => xoá spot
      await SpotRepository().deleteSpot(spotId);
    }
  }

// Hàm xoá sub-collection theo batch
  Future<void> _deleteCollection(CollectionReference collectionRef,
      {int batchSize = 500}) async {
    QuerySnapshot snapshot = await collectionRef.limit(batchSize).get();
    while (snapshot.docs.isNotEmpty) {
      WriteBatch batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot = await collectionRef.limit(batchSize).get();
    }
  }

  /// Cập nhật checkin
  Future<void> updateCheckIn(
      String checkInId, Map<String, dynamic> updates) async {
    try {
      updates["updatedAt"] = FieldValue.serverTimestamp();

      await _db.collection("checkins").doc(checkInId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleLike(
      String checkinId, String userId) async {
    final checkinRef = getCheckinRef(checkinId);
    final reactionRef = getReactionRef(checkinId, userId);

    return _db.runTransaction((transaction) async {
      final checkinSnap = await transaction.get(checkinRef);
      if (!checkinSnap.exists) {
        throw Exception("Checkin not found");
      }

      final reactionSnap = await transaction.get(reactionRef);

      int likesCount = checkinSnap['likesCount'] ?? 0;
      int dislikesCount = checkinSnap['dislikesCount'] ?? 0;
      String? newType;

      if (!reactionSnap.exists) {
        // chưa có -> tạo like
        transaction.set(reactionRef, {'type': 'like'});
        likesCount++;
        newType = "like";
      } else {
        final currentType = reactionSnap['type'];
        if (currentType == 'like') {
          // đã like -> bỏ like
          transaction.delete(reactionRef);
          likesCount--;
          newType = null;
        } else if (currentType == 'dislike') {
          // đang dislike -> chuyển thành like
          transaction.update(reactionRef, {'type': 'like'});
          dislikesCount--;
          likesCount++;
          newType = "like";
        }
      }

      transaction.update(checkinRef, {
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
      });

      return {
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
        'reaction': newType, // null, like, dislike
      };
    });
  }

  Future<Map<String, dynamic>> toggleDislike(
      String checkinId, String userId) async {
    final checkinRef = getCheckinRef(checkinId);
    final reactionRef = getReactionRef(checkinId, userId);

    return _db.runTransaction((transaction) async {
      final checkinSnap = await transaction.get(checkinRef);
      if (!checkinSnap.exists) {
        throw Exception("Checkin not found");
      }

      final reactionSnap = await transaction.get(reactionRef);

      int likesCount = checkinSnap['likesCount'] ?? 0;
      int dislikesCount = checkinSnap['dislikesCount'] ?? 0;
      String? newType;

      if (!reactionSnap.exists) {
        // chưa có -> tạo dislike
        transaction.set(reactionRef, {'type': 'dislike'});
        dislikesCount++;
        newType = "dislike";
      } else {
        final currentType = reactionSnap['type'];
        if (currentType == 'dislike') {
          // đã dislike -> bỏ dislike
          transaction.delete(reactionRef);
          dislikesCount--;
          newType = null;
        } else if (currentType == 'like') {
          // đang like -> chuyển thành dislike
          transaction.update(reactionRef, {'type': 'dislike'});
          likesCount--;
          dislikesCount++;
          newType = "dislike";
        }
      }

      transaction.update(checkinRef, {
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
      });

      return {
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
        'reaction': newType,
      };
    });
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

    return _db.runTransaction((transaction) async {
      final checkinSnap = await transaction.get(checkinRef);
      final reactionSnap = await transaction.get(reactionRef);

      int likesCount = checkinSnap['likesCount'] ?? 0;
      int dislikesCount = checkinSnap['dislikesCount'] ?? 0;

      String? currentType;
      if (reactionSnap.exists) {
        currentType = reactionSnap['type'] as String?;
      }

      //Nếu user bấm lại cùng loại → xóa reaction
      if (currentType == type) {
        transaction.delete(reactionRef);

        if (type == 'like') likesCount--;
        if (type == 'dislike') dislikesCount--;

        transaction.update(checkinRef, {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
        });

        return {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
          'isLiked': false,
          'isDisliked': false,
        };
      }

      // Nếu user chuyển từ like → dislike hoặc ngược lại
      if (currentType != null && currentType != type) {
        if (currentType == 'like') likesCount--;
        if (currentType == 'dislike') dislikesCount--;

        if (type == 'like') likesCount++;
        if (type == 'dislike') dislikesCount++;

        transaction.set(reactionRef, {
          'type': type,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(checkinRef, {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
        });

        return {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
          'isLiked': type == 'like',
          'isDisliked': type == 'dislike',
        };
      }

      // Nếu user chưa reaction → tạo mới
      if (currentType == null) {
        if (type == 'like') likesCount++;
        if (type == 'dislike') dislikesCount++;

        transaction.set(reactionRef, {
          'type': type,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(checkinRef, {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
        });

        return {
          'likesCount': likesCount,
          'dislikesCount': dislikesCount,
          'isLiked': type == 'like',
          'isDisliked': type == 'dislike',
        };
      }

      return {
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
        'isLiked': currentType == 'like',
        'isDisliked': currentType == 'dislike',
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

  Future<List<EnhancedCheckInModel>> getCheckInsBySpot(String spotId) async {
    final snapshot = await _db
        .collection("checkins")
        .where("spotId", isEqualTo: spotId)
        .get();

    final checkins =
        snapshot.docs.map((doc) => CheckInModel.fromJson(doc.data())).toList();

    checkins.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<EnhancedCheckInModel> enhancedList = [];

    for (final checkin in checkins) {
      final profileDoc =
          await _db.collection('profiles').doc(checkin.userId).get();
      final categoryDoc =
          await _db.collection('categories').doc(checkin.categoryId).get();
      final vibeDoc = await _db.collection('vibe').doc(checkin.vibeId).get();

      enhancedList.add(EnhancedCheckInModel(
        checkIn: checkin,
        profile: profileDoc.exists
            ? ProfileModel.fromJson(profileDoc.data()!)
            : null,
        category: categoryDoc.exists
            ? CategoryModel.fromJson(categoryDoc.data()!)
            : null,
        vibe: vibeDoc.exists ? VibeModel.fromJson(vibeDoc.data()!) : null,
      ));
    }

    return enhancedList;
  }

  /// Upload 1 ảnh checkin
  Future<String> uploadImage(
    String userId,
    String checkInId,
    String fileName,
    Uint8List fileBytes,
  ) async {
    final ref = _storage.ref().child("checkins/$userId/$checkInId/$fileName");

    final uploadTask = await ref.putData(fileBytes);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Cập nhật danh sách ảnh cho checkin
  Future<void> updateCheckInImages(
    String checkInId,
    List<String> urls,
  ) async {
    await _db.collection("checkins").doc(checkInId).update({
      "images": urls,
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
}
