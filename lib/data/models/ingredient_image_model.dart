class IngredientImageModel {
  final String id;
  final String ingredientName;
  final String imageUrl;
  final String localPath;
  final DateTime createdAt;
  final DateTime lastAccessed;

  IngredientImageModel({
    required this.id,
    required this.ingredientName,
    required this.imageUrl,
    required this.localPath,
    required this.createdAt,
    required this.lastAccessed,
  });

  factory IngredientImageModel.fromJson(Map<String, dynamic> json) {
    return IngredientImageModel(
      id: json['id'] as String,
      ingredientName: json['ingredient_name'] as String,
      imageUrl: json['image_url'] as String,
      localPath: json['local_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastAccessed: DateTime.parse(json['last_accessed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient_name': ingredientName,
      'image_url': imageUrl,
      'local_path': localPath,
      'created_at': createdAt.toIso8601String(),
      'last_accessed': lastAccessed.toIso8601String(),
    };
  }

  IngredientImageModel copyWith({
    String? id,
    String? ingredientName,
    String? imageUrl,
    String? localPath,
    DateTime? createdAt,
    DateTime? lastAccessed,
  }) {
    return IngredientImageModel(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}
