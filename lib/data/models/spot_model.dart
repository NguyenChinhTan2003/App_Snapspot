import 'package:cloud_firestore/cloud_firestore.dart';

class SpotModel {
  final String id;
  final double latitude;
  final double longitude;
  final String categoryId;
  final String categoryIcon;
  final String? name;
  final DateTime createdAt;

  SpotModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.categoryId,
    required this.categoryIcon,
    this.name,
    required this.createdAt,
  });

  factory SpotModel.fromJson(Map<String, dynamic> json) {
    return SpotModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      categoryIcon: json['categoryIcon'] as String,
      name: json['name'] as String?,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "latitude": latitude,
      "longitude": longitude,
      "categoryId": categoryId,
      "categoryIcon": categoryIcon,
      "name": name,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
