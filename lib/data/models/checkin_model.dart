import 'package:app_snapspot/data/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInModel {
  final String id;
  final String userId;
  final String spotId;
  final String name;
  final String content;
  final String categoryId;
  final String categoryIcon;
  final String vibeId;
  final String vibeIcon;
  final double latitude;
  final double longitude;
  final List<String> images;
  final DateTime createdAt;
  final CategoryModel? category;
  final int likesCount;
  final int dislikesCount;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.name,
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
    this.likesCount = 0,
    this.dislikesCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "spotId": spotId,
      "name": name,
      "content": content,
      "categoryId": categoryId,
      "categoryIcon": categoryIcon,
      "vibeId": vibeId,
      "vibeIcon": vibeIcon,
      "latitude": latitude,
      "longitude": longitude,
      "images": images,
      "createdAt": Timestamp.fromDate(createdAt),
      "likesCount": likesCount,
      "dislikesCount": dislikesCount,
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
      spotId: json["spotId"] ?? "",
      name: json["name"] ?? "",
      content: json["content"] ?? "",
      categoryId: json["categoryId"] ?? "",
      categoryIcon: json["categoryIcon"] ?? "",
      vibeId: json["vibeId"] ?? "",
      vibeIcon: json["vibeIcon"] ?? "",
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      images: List<String>.from(json["images"] ?? []),
      createdAt: createdAt,
      likesCount: json["likesCount"] ?? 0,
      dislikesCount: json["dislikesCount"] ?? 0,
    );
  }

  CheckInModel copyWith({
    String? name,
    String? content,
    String? vibeId,
    String? vibeIcon,
    List<String>? images,
    int? likesCount,
    int? dislikesCount,
  }) {
    return CheckInModel(
      id: id,
      userId: userId,
      spotId: spotId,
      name: name ?? this.name,
      content: content ?? this.content,
      categoryId: categoryId,
      categoryIcon: categoryIcon,
      vibeId: vibeId ?? this.vibeId,
      vibeIcon: vibeIcon ?? this.vibeIcon,
      latitude: latitude,
      longitude: longitude,
      images: images ?? this.images,
      createdAt: createdAt,
      category: category,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
    );
  }
}
