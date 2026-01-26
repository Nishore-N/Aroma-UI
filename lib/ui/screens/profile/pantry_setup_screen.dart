import 'package:flutter/material.dart';
import 'scales_screen.dart';
import 'stock_levels_screen.dart';

class PantrySetupScreen extends StatelessWidget {
  const PantrySetupScreen({super.key});

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pantry Setup',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Manage scales & stock levels',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          _row(
            context,
            title: 'Scales',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScalesScreen()),
            ),
          ),
          _row(
            context,
            title: 'Stock levels',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockLevelsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
