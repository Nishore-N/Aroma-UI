import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../state/pantry_state.dart';
import '../../../data/services/pantry_list_service.dart';
import 'generate_recipe_screen.dart';
import '../auth/login_screen.dart';

class PantrySelectionScreen extends StatefulWidget {
  const PantrySelectionScreen({super.key});

  @override
  State<PantrySelectionScreen> createState() => _PantrySelectionScreenState();
}

class _PantrySelectionScreenState extends State<PantrySelectionScreen> {
  final PantryListService _pantryListService = PantryListService();
  bool _isLoading = false;
  List<String> _pantryIngredients = [];
  bool _includeAllPantry = false;
  bool _manualSelection = false;

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use remote server data for consistency
      final pantryItems = await _pantryListService.fetchPantryItems();
      
      final ingredients = pantryItems
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      
      setState(() {
        _pantryIngredients = ingredients;
        _isLoading = false;
      });
      
      print("🔍 DEBUG: Loaded remote pantry ingredients: ${ingredients.length} items");
      print("🔍 DEBUG: Remote ingredients: $ingredients");
      
    } catch (e) {
      print("❌ Error loading remote pantry ingredients: $e");
      setState(() {
        _isLoading = false;
      });
      
      // Fallback to local PantryState if remote fails
      try {
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.loadPantry();
        
        final fallbackIngredients = pantryState.pantryItems.map((item) => item.name).toList();
        
        setState(() {
          _pantryIngredients = fallbackIngredients;
        });
        
        print("🔍 DEBUG: Fallback to local pantry ingredients: ${fallbackIngredients.length} items");
      } catch (fallbackError) {
        print("❌ Error in fallback to local pantry: $fallbackError");
      }
    }
  }

  void _refreshPantryInBackground() async {
    try {
      final pantryItems = await _pantryListService.fetchPantryItems();
      
      final pantryIngredients = pantryItems
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      // Update UI if fresh data is different
      if (pantryIngredients.length != _pantryIngredients.length) {
        setState(() {
          _pantryIngredients = pantryIngredients;
        });
        print("🔍 DEBUG: Refreshed pantry ingredients in background: ${pantryIngredients.length} items");
      }
    } catch (e) {
      print("🔍 DEBUG: Background refresh failed, keeping cached data: $e");
    }
  }

  void _generateWeeklyRecipes() {
    if (_includeAllPantry) {
      // Use all pantry ingredients
      print("🔍 DEBUG: Using all pantry ingredients: $_pantryIngredients");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenerateRecipeScreen(
            usePantryIngredients: true,
            pantryIngredients: _pantryIngredients,
          ),
        ),
      );
    } else if (_manualSelection) {
      // Go to manual selection screen
      print("🔍 DEBUG: Going to manual ingredient selection");
      // TODO: Navigate to manual ingredient selection screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual selection coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option to continue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (!authService.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weekly Recipe Generation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose your recipe generation preference:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Include All Pantry Items Option
                    _buildOptionCard(
                      title: 'Include All My Pantry Items',
                      subtitle: 'Use all ingredients from your pantry (${_pantryIngredients.length} items)',
                      icon: Icons.inventory_2_outlined,
                      isSelected: _includeAllPantry,
                      onTap: () {
                        setState(() {
                          _includeAllPantry = true;
                          _manualSelection = false;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Manual Selection Option
                    _buildOptionCard(
                      title: 'Select Manually',
                      subtitle: 'Choose specific ingredients for recipe generation',
                      icon: Icons.touch_app_outlined,
                      isSelected: _manualSelection,
                      onTap: () {
                        setState(() {
                          _includeAllPantry = false;
                          _manualSelection = true;
                        });
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_includeAllPantry || _manualSelection) ? _generateWeeklyRecipes : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Generate Weekly Recipes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7A4A).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7A4A) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFFF7A4A).withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7A4A) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFFF7A4A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
