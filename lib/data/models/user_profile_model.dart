import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isCustomAvatar; 
  final DateTime createdAt;

  ProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isCustomAvatar = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isCustomAvatar': isCustomAvatar,
      'createdAt': createdAt,
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uid: json['uid'],
      displayName: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      isCustomAvatar: json['isCustomAvatar'] ?? false, 
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    );
  }

  ProfileModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isCustomAvatar,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isCustomAvatar: isCustomAvatar ?? this.isCustomAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}