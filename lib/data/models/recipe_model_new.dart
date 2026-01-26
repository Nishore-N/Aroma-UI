class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int rating;
  final String duration;
  final bool isFavorite;
  final List<String> tags;
  final String difficulty;
  final int servings;
  final List<Map<String, dynamic>> ingredients;
  final List<String> steps;
  final String? videoUrl;
  final String? description;
  final String? source;
  final DateTime? createdAt;
  final bool isPremium;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.rating = 0,
    this.duration = '30 min',
    this.isFavorite = false,
    this.tags = const [],
    this.difficulty = 'Medium',
    this.servings = 2,
    this.ingredients = const [],
    this.steps = const [],
    this.videoUrl,
    this.description,
    this.source,
    this.createdAt,
    this.isPremium = false,
  });

  // Add fromJson and toJson methods if needed
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Recipe',
      imageUrl: json['imageUrl'] ?? '',
      rating: json['rating'] ?? 0,
      duration: json['duration'] ?? '30 min',
      isFavorite: json['isFavorite'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? 'Medium',
      servings: json['servings'] ?? 2,
      ingredients: List<Map<String, dynamic>>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      videoUrl: json['videoUrl'],
      description: json['description'],
      source: json['source'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'rating': rating,
      'duration': duration,
      'isFavorite': isFavorite,
      'tags': tags,
      'difficulty': difficulty,
      'servings': servings,
      'ingredients': ingredients,
      'steps': steps,
      'videoUrl': videoUrl,
      'description': description,
      'source': source,
      'createdAt': createdAt?.toIso8601String(),
      'isPremium': isPremium,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? rating,
    String? duration,
    bool? isFavorite,
    List<String>? tags,
    String? difficulty,
    int? servings,
    List<Map<String, dynamic>>? ingredients,
    List<String>? steps,
    String? videoUrl,
    String? description,
    String? source,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      videoUrl: videoUrl ?? this.videoUrl,
      description: description ?? this.description,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
