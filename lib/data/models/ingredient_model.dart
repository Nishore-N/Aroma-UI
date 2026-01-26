class IngredientModel {
  final String? id;
  final String emoji;
  final String name;
  final int match;
  final double quantity;
  final String unit;
  final double price;

  IngredientModel({
    this.id,
    this.emoji = '🍴',
    required this.name,
    this.match = 100,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.price = 0.0,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMatch = json['match'];
    int parsedMatch;

    if (rawMatch is int) {
      parsedMatch = rawMatch;
    } else if (rawMatch is String) {
      parsedMatch = int.tryParse(rawMatch) ?? 0;
    } else {
      parsedMatch = 0;
    }

    return IngredientModel(
      id: json['id']?.toString(),
      emoji: (json['emoji'] ?? '🍴') as String,
      name: (json['name'] ?? '') as String,
      match: parsedMatch,
      quantity: (json['quantity'] != null) ? (json['quantity'] is int ? (json['quantity'] as int).toDouble() : (json['quantity'] as num).toDouble()) : 1.0,
      unit: (json['unit'] ?? 'pcs') as String,
      price: (json['price'] != null) ? (json['price'] is int ? (json['price'] as int).toDouble() : (json['price'] as num).toDouble()) : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'emoji': emoji,
      'name': name,
      'match': match,
      'quantity': quantity,
      'unit': unit,
      'price': price,
    };
  }
}

