import 'package:flutter/material.dart';
import '../sheets/single_select_sheet.dart';
import '../sheets/multi_select_sheet.dart';
import '../sheets/servings_sheet.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  static const Color accent = Color(0xFFFF7A4A);

  String weekStart = 'Sunday';
  List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday'];
  int servings = 1;
  List<String> meals = ['Breakfast', 'Brunch', 'Lunch', 'Dessert'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Meal Planner',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'meal schedules & preferences',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),

          _row(
            'Week Start Day',
            weekStart,
            () async {
              final res = await SingleSelectSheet.open(
                context,
                title: 'Week Start Day',
                subtitle: 'Choose the start day of your week',
                options: const [
                  'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
                ],
                selected: weekStart,
              );
              if (res != null) setState(() => weekStart = res);
            },
          ),

          _row(
            'Days to Consider',
            '${days.first} + ${days.length - 1} More',
            () async {
              final res = await MultiSelectSheet.open(
                context,
                title: 'Days to Consider',
                subtitle: 'Select the days to plan meals for',
                options: const [
                  'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
                ],
                selected: days,
              );
              if (res != null) setState(() => days = res);
            },
            highlight: true,
          ),

          _row(
            'Number of Servings',
            '$servings pax',
            () async {
              final res = await ServingsSheet.open(context, servings);
              if (res != null) setState(() => servings = res);
            },
            highlight: true,
          ),

          _row(
            'Meals & Meal Types',
            '${meals.first} + ${meals.length - 1} More',
            () async {
              final res = await MultiSelectSheet.open(
                context,
                title: 'Meals & Meal Types',
                subtitle: 'Set the number of meals and types per day',
                options: const [
                  'Breakfast','Brunch','Lunch','Afternoon Snack',
                  'Evening Snack','Dinner','Dessert','Supper','Tea Time'
                ],
                selected: meals,
              );
              if (res != null) setState(() => meals = res);
            },
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value, VoidCallback onTap,
      {bool highlight = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Text(
            value,
            style: TextStyle(
              color: highlight ? accent : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: onTap,
        ),
        Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}
