import 'package:flutter/material.dart';

class MyTastesScreen extends StatefulWidget {
  const MyTastesScreen({super.key});

  @override
  State<MyTastesScreen> createState() => _MyTastesScreenState();
}

class _MyTastesScreenState extends State<MyTastesScreen> {
  // ✅ Single selection per category
  String? selectedCuisine;
  String? selectedDiet;
  String? selectedCookware;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
  padding: const EdgeInsets.only(right: 16),
  child: GestureDetector(
    onTap: _savePreferences,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // ✅ same pill
        border: Border.all(
          color: Colors.orange,
          width: 1.2,
        ),
      ),
      child: const Text(
        'Save',
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
)

        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ✅ TITLE
              const Text(
                'My Tastes',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'your cuisines & dietary needs',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // ✅ CUISINE
              const Text(
                'Cuisine preference',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _chipGroup(
                options: ['Indian', 'Chinese', 'Italian', 'Mexican', 'Thai', 'Continental'],
                selected: selectedCuisine,
                onSelected: (val) => setState(() => selectedCuisine = val),
              ),

              const SizedBox(height: 24),

              // ✅ DIETARY
              const Text(
                'Dietary Restrictions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _chipGroup(
                options: [
                  'Vegetarian',
                  'Non-Vegetarian',
                  'Vegan',
                  'Eggetarian',
                  'Paleo',
                  'Keto',
                ],
                selected: selectedDiet,
                onSelected: (val) => setState(() => selectedDiet = val),
              ),

              const SizedBox(height: 24),

              // ✅ COOKWARE
              const Text(
                'Cookware',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _chipGroup(
                options: [
                  'Microwave Oven',
                  'Gas Stove',
                  'Electric Stove',
                  'Induction Cooktop',
                  'Blender',
                  'Grill',
                ],
                selected: selectedCookware,
                onSelected: (val) => setState(() => selectedCookware = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CHIP UI (SINGLE SELECT)
  Widget _chipGroup({
  required List<String> options,
  required String? selected,
  required Function(String) onSelected,
}) {
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: options.map((item) {
      final isSelected = selected == item;

      return GestureDetector(
        onTap: () => onSelected(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30), // ✅ pill shape
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.orange : Colors.black,
            ),
          ),
        ),
      );
    }).toList(),
  );
}


  // ✅ SAVE ACTION
  void _savePreferences() {
    debugPrint('Cuisine: $selectedCuisine');
    debugPrint('Diet: $selectedDiet');
    debugPrint('Cookware: $selectedCookware');

    // Later → Save to Firebase / API
    Navigator.pop(context);
  }
}
