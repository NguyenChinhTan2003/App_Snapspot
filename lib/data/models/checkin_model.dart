import 'package:app_snapspot/data/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInModel {
  final String id;
  final String userId;
  final String content;
  final String categoryId;
  final String categoryIcon; // <- Lưu trực tiếp từ Firestore
  final String vibeId;
  final String vibeIcon;
  final double latitude;
  final double longitude;
  final List<String> images;
  final DateTime createdAt;
  final CategoryModel? category;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.categoryId,
    required this.categoryIcon,
    required this.vibeId,
    required this.vibeIcon,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.createdAt,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "content": content,
      "categoryId": categoryId,
      "categoryIcon": categoryIcon,
      "vibeId": vibeId,
      "vibeIcon": vibeIcon,
      "latitude": latitude,
      "longitude": longitude,
      "images": images,
      "createdAt": createdAt,
    };
  }

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final createdAtRaw = json["createdAt"];

    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else {
      createdAt = DateTime.now();
    }

    return CheckInModel(
      id: json["id"] ?? "",
      userId: json["userId"] ?? "",
      content: json["content"] ?? "",
      categoryId: json["categoryId"] ?? "",
      categoryIcon: json["categoryIcon"] ?? "",
      vibeId: json["vibeId"] ?? "",
      vibeIcon: json["vibeIcon"] ?? "",
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      images: List<String>.from(json["images"] ?? []),
      createdAt: createdAt,
    );
  }
}
