import 'dart:typed_data';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/enhanced_checkin_model.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';

class CheckInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Tạo checkin mới
  Future<void> createCheckIn(CheckInModel checkIn, String spotId) async {
    final data = checkIn.toJson();
    data["spotId"] = spotId;
    await _db.collection("checkins").doc(checkIn.id).set(data);
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
    final snapshot = await _db
        .collection("checkins")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CheckInModel.fromJson(doc.data()))
        .toList();
  }

  /// Lấy chi tiết 1 checkin
  Future<CheckInModel?> getCheckInById(String checkInId) async {
    final snapshot = await _db.collection("checkins").doc(checkInId).get();
    if (!snapshot.exists) return null;
    return CheckInModel.fromJson(snapshot.data()!);
  }
}
