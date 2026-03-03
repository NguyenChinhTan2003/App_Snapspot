class VibeModel {
  final String id;
  final String name;
  final String icon;

  VibeModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  factory VibeModel.fromJson(Map<String, dynamic> json) {
    return VibeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  VibeModel copyWith({
    String? id,
    String? name,
    String? icon,
  }) {
    return VibeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
