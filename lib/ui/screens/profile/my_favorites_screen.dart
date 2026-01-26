import 'package:flutter/material.dart';

class MyFavoritesScreen extends StatelessWidget {
  const MyFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'My Favorites',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ✅ SUBTITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Manage your saved and favorite recipes.',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // ✅ EMPTY STATE
          const Expanded(
            child: Center(
              child: Text(
                'No favorites found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
