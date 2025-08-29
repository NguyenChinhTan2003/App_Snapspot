import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';

class ProfileRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _firestore.collection('profiles').doc(uid).get();
    if (!doc.exists) return null;
    return ProfileModel.fromJson(doc.data()!);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final data = {
      'uid': profile.uid,
      'name': profile.displayName,
      'email': profile.email,
      'photoUrl': profile.photoUrl,
      'isCustomAvatar': profile.isCustomAvatar, 
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('profiles').doc(profile.uid).set(
          data,
          SetOptions(merge: true), 
        );
  }

  Future<void> updateFields(
    String uid, {
    String? displayName,
    String? photoUrl,
    bool? isCustomAvatar, 
  }) async {
    final update = <String, dynamic>{};
    if (displayName != null) update['name'] = displayName;
    if (photoUrl != null) update['photoUrl'] = photoUrl;
    if (isCustomAvatar != null) update['isCustomAvatar'] = isCustomAvatar;

    if (update.isNotEmpty) {
      await _firestore.collection('profiles').doc(uid).update(update);
    }
  }

  Future<String?> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref().child('profiles/$uid/avatar.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}