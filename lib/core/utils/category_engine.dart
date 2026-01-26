class CategoryEngine {
  static final Map<String, List<String>> _categories = {

    // 🥦 Fruits & Vegetables
    "Fruits & Vegetables": [
      "fruit", "vegetable", "veg", "leaf", "leaves", "greens",
      "onion", "tomato", "potato", "carrot", "beetroot",
      "banana", "apple", "orange", "grape", "anar", "pomegranate",
      "aubergine", "brinjal", "eggplant", "aloe", "avocado",
      "spinach", "cabbage", "cauliflower", "broccoli",
      "cherry tomato", "capsicum", "chilli", "okra", "ladies finger"
    ],

    // 🥛 Dairy & Alternatives
    "Dairy & Alternatives": [
      "milk", "cheese", "paneer", "curd", "yogurt", "butter",
      "cream", "ghee", "lassi", "buttermilk", "whey",
      "soy milk", "almond milk", "oat milk"
    ],

    // 🍗 Eggs, Meat & Fish
    "Eggs, Meat & Fish": [
      "egg", "eggs", "chicken", "fish", "tuna", "salmon",
      "prawn", "shrimp", "crab", "mutton", "beef", "pork",
      "lamb", "duck", "meat", "seafood"
    ],

    // 🌾 Grains & Staples
    "Grains & Staples": [
      "atta", "wheat", "rice", "basmati", "brown rice",
      "dal", "arhar", "toor", "moong", "urad", "chana",
      "flour", "maida", "rava", "semolina",
      "oats", "corn", "millet", "quinoa", "barley"
    ],

    // 🌶 Spices & Masalas
    "Spices & Masalas": [
      "powder", "masala", "chilli", "pepper", "jeera",
      "cumin", "coriander", "dhania", "turmeric", "haldi",
      "amchur", "garam masala", "cardamom", "clove",
      "cinnamon", "bay leaf", "mustard seed"
    ],

    // 🛢 Oils & Condiments
    "Oils & Condiments": [
      "oil", "ghee", "butter oil",
      "mustard oil", "sunflower oil", "olive oil",
      "vinegar", "soy sauce", "ketchup", "mayonnaise",
      "chutney", "pickle", "jam", "honey"
    ],

    // 🍽 Ready-to-Eat & Cooked Food
    "Ready-to-Eat": [
      "meal", "meals", "parotta", "paratha", "roti", "naan",
      "soup", "omelette", "fried", "roast", "grilled",
      "biryani", "curry", "rice bowl", "noodles",
      "pasta", "pizza", "sandwich", "burger", "wrap"
    ],

    // 🥜 Nuts & Dry Fruits
    "Nuts & Dry Fruits": [
      "almond", "cashew", "pista", "walnut", "peanut",
      "nut", "raisins", "dates", "fig", "dry fruit"
    ],

    // 🍪 Snacks & Bakery
    "Snacks & Bakery": [
      "biscuit", "cookie", "cracker", "chips", "namkeen",
      "cake", "bread", "bun", "toast", "rusk",
      "muffin", "croissant"
    ],

    // ☕ Beverages
    "Beverages": [
      "tea", "coffee", "juice", "soft drink",
      "soda", "cola", "water", "energy drink",
      "milkshake", "smoothie"
    ],
  };

  static String getCategory(String name) {
    final n = name.toLowerCase().trim();

    for (final entry in _categories.entries) {
      if (entry.value.any((k) => n.contains(k))) {
        return entry.key;
      }
    }
    return "Others";
  }
}
