class WeeklyMealPlan {
  final List<DayPlan> days;

  WeeklyMealPlan({required this.days});

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyMealPlan(
      days: (json['Days'] as List? ?? [])
          .map((dayJson) => DayPlan.fromJson(dayJson))
          .toList(),
    );
  }
}

class DayPlan {
  final int day;
  final List<Meal> meals;

  DayPlan({required this.day, required this.meals});

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: json['Day'] ?? 1,
      meals: (json['Meals'] as List? ?? [])
          .map((mealJson) => Meal.fromJson(mealJson))
          .toList(),
    );
  }
}

class Meal {
  final String id;
  final String mealType;
  final String recipeName;
  final String cookingTime;
  final String shortDescription;
  String? imageUrl; // To be populated by background generation

  Meal({
    required this.id,
    required this.mealType,
    required this.recipeName,
    required this.cookingTime,
    required this.shortDescription,
    this.imageUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id']?.toString() ?? '',
      mealType: json['Meal_Type']?.toString() ?? '',
      recipeName: json['Recipe Name']?.toString() ?? 'Unknown Recipe',
      cookingTime: json['Cooking Time']?.toString() ?? '30 min',
      shortDescription: json['Short Description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Meal_Type': mealType,
      'Recipe Name': recipeName,
      'Cooking Time': cookingTime,
      'Short Description': shortDescription,
      'image_url': imageUrl,
    };
  }
}
