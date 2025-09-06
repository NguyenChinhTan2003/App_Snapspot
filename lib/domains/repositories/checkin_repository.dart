import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CheckInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createCheckIn(CheckInModel checkIn) async {
    await _db.collection("checkins").doc(checkIn.id).set(checkIn.toJson());
  }

  Future<List<CheckInModel>> getCheckIns() async {
    final snapshot = await _db.collection("checkins").get();
    return snapshot.docs
        .map((doc) => CheckInModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMarkerData() async {
    final snapshot = await _db.collection("checkins").get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'categoryIcon': data['categoryIcon'],
      };
    }).toList();
  }

  Future<String> uploadImage(
      String uid, String checkInId, String fileName, Uint8List fileData) async {
    final ref = _storage.ref().child('checkins/$uid/$checkInId/$fileName');
    await ref.putData(fileData);
    return await ref.getDownloadURL();
  }

  Future<void> updateCheckInImages(String checkInId, List<String> urls) async {
    await FirebaseFirestore.instance
        .collection("checkins")
        .doc(checkInId)
        .update({
      "images": urls,
    });
  }
}
