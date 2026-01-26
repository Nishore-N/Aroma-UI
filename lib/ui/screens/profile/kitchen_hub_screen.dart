import 'package:flutter/material.dart';
import 'my_tastes_screen.dart';
import 'pantry_setup_screen.dart';
import 'meal_planner_screen.dart';
import 'my_favorites_screen.dart';
import 'region_seasons_screen.dart';


class KitchenHubScreen extends StatelessWidget {
  const KitchenHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Kitchen Hub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          _hubItem(
  title: 'My Tastes',
  subtitle: 'Customize cuisines & dietary needs',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyTastesScreen()),
    );
  },
),


          _hubItem(
  title: 'Pantry Setup',
  subtitle: 'Scales, stock levels, and shopping lists.',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantrySetupScreen()),
    );
  },
),


          _hubItem(
  title: 'Meal Planner',
  subtitle: 'Weekly meal schedule and preferences',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MealPlannerScreen(),
      ),
    );
  },
),


          _hubItem(
  title: 'My Favorites',
  subtitle: 'Manage your saved and favorite recipes.',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyFavoritesScreen(),
      ),
    );
  },
),


          _hubItem(
  title: 'Region & Seasons',
  subtitle: 'Your regional preferences',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegionSeasonsScreen(),
      ),
    );
  },
),

        ],
      ),
    );
  }

  // ✅ ROW SAME AS IMAGE
  Widget _hubItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
