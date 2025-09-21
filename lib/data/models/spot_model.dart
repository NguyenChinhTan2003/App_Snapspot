import 'package:cloud_firestore/cloud_firestore.dart';

class SpotModel {
  final String id;
  final double latitude;
  final double longitude;
  final String? name;
  final String categoryId;
  final String categoryIcon;
  final DateTime createdAt;

  SpotModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    required this.categoryId,
    required this.categoryIcon,
    required this.createdAt,
  });

  SpotModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? name,
    String? categoryId,
    String? categoryIcon,
    DateTime? createdAt,
  }) {
    return SpotModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'categoryId': categoryId,
      'categoryIcon': categoryIcon,
      'createdAt': createdAt,
    };
  }

  factory SpotModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else {
      createdAt = DateTime.now();
    }

    return SpotModel(
      id: json['id'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: (json['name'] as String?)?.trim(),
      categoryId: json['categoryId'] ?? '',
      categoryIcon: json['categoryIcon'] ?? '',
      createdAt: createdAt,
    );
  }
}
