import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../data/services/home_recipe_service.dart';
import '../../../data/services/pantry_list_service.dart';
import '../../../state/pantry_state.dart';
import '../../widgets/primary_button.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../home/generate_recipe_screen.dart';
import '../preferences/cooking_preference_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../add_ingredients/ingredient_entry_screen.dart';
import '../calendar/select_ingredients_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:aroma/ui/screens/home/pantry_selection_screen.dart';
import '../../../data/services/pantry_list_service.dart';
import '../home/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/cooking_loader.dart';

const Color kAccent = Color(0xFFFF7A4A);

class CalendarEmptyScreen extends StatefulWidget {
  final String phoneNumber;
  
  const CalendarEmptyScreen({super.key, this.phoneNumber = ''});

  @override
  State<CalendarEmptyScreen> createState() => _CalendarEmptyScreenState();
}

class _CalendarEmptyScreenState extends State<CalendarEmptyScreen> 
    with TickerProviderStateMixin {
  final HomeRecipeService _homeRecipeService = HomeRecipeService();
  final PantryListService _pantryListService = PantryListService();
  bool _isLoading = false;
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    // Disable animation - always show static content
    _showAnimation = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content (always rendered - old UI)
            _buildMainContent(),
            
            // Loading Overlay (show on top when loading)
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.95),
                child: const CookingLoader(
                  message: "cooking recipes with your pantry items...",
                ),
              ),
          ],
        ),
      ),
      // 🔥 Same Footer Navigation as HomeScreen
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _buildMainContent() {
    // Always show static content (old UI) - remove animated content
    return _buildStaticContent();
  }

  Widget _buildAnimatedContent() {
    return Column(
      children: [
        // Back Button
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Animated Illustration + text
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Static Chef Icon (no animation)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: SvgPicture.asset(
                  'assets/images/chef_icon.svg',
                  width: 44,
                  height: 44,
                  colorFilter: const ColorFilter.mode(kAccent, BlendMode.srcIn),
                ),
              ),
              
              const SizedBox(height: 40),

              // Static Text (no animation)
              const Text(
                'Your cooking calendar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'is empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: kAccent,
                ),
              ),

              const SizedBox(height: 32),

              // Static Description (no animation)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Start planning delicious meals for the week based on your pantry and preferences.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 100),

        // Generate Weekly Recipe button (static)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => _openGenerateSheet(context),
              child: const Text(
                'Generate Weekly Recipe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStaticContent() {
    return Column(
      children: [
        // Back Button
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Static Illustration + text
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 220,
                child: CachedNetworkImage(
                  imageUrl: 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Your cooking calendar\nis empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Start planning delicious meals for the week based on your pantry and preferences.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Generate Weekly Recipe button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => _openGenerateSheet(context),
              child: const Text(
                'Generate Weekly Recipe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 🔥 EXACT SAME FOOTER AS HOME SCREEN (copied & adapted)
  // --------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // HOME
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(phoneNumber: widget.phoneNumber),
                ),
              );
            },
            icon: SvgPicture.asset(
              'assets/images/home_icon.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(Color(0xFFB0B0B0), BlendMode.srcIn),
            ),
          ),

          // SEARCH
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/images/search_icon.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Color(0xFFB0B0B0), BlendMode.srcIn),
            ),
          ),

          // CENTER ORANGE BUTTON
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IngredientEntryScreen(
                    mode: ScanMode.cooking,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFC6E3C),
              ),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                'assets/images/chef_icon.svg',
                width: 44,
                height: 44,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),

          // CALENDAR → ACTIVE PAGE
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/images/calendar_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFFFC6E3C), BlendMode.srcIn),
            ),
          ),

          // PROFILE
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(phoneNumber: ''),
                ),
              );
            },
            icon: SvgPicture.asset(
              'assets/images/profile_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFFB0B0B0), BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Sheet
  // --------------------------------------------------------------------------
  void _openGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hey there!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'How do you want to add ingredients\nfor your weekly recipe?',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Let me select ingredients
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kAccent, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectIngredientsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Let me select my ingredients',
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Include pantry items
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _generateWeeklyRecipesWithPantryItems();
                    },
                    child: const Text(
                      'Include all pantry items',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateWeeklyRecipesWithPantryItems() async {
    try {
      print('🔄 [Calendar] Starting recipe generation with pantry items...');
      
      // Fetch actual pantry items from remote server
      final pantryItems = await _pantryListService.fetchPantryItems();
      
      // Extract ingredient names from pantry items
      final ingredients = pantryItems
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      
      print('🥦 Found ${ingredients.length} remote pantry items: $ingredients');
      
      if (ingredients.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No pantry items found. Please add items to your pantry first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Navigate directly to CookingPreferenceScreen without loading animation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CookingPreferenceScreen(
            ingredients: ingredients.map((name) => {"item": name, "quantity": "1"}).toList(),
            isWeekly: true,
          ),
        ),
      );
      
    } catch (e) {
      print('❌ Error generating weekly recipes: $e');
      // Reset loading state on error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Failed to generate recipes';
        
        if (e.toString().contains('receive timeout')) {
          errorMessage = 'Recipe generation is taking longer than expected. Please try again in a moment.';
        } else if (e.toString().contains('connect timeout')) {
          errorMessage = 'Unable to connect to the recipe service. Please check your connection.';
        } else {
          errorMessage = 'Failed to generate recipes: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () async {
                // Clear any existing error state and retry after a short delay
                print('🔄 [Calendar] Retrying recipe generation...');
                
                // Wait a moment before retrying to prevent immediate failures
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Retry the recipe generation
                await _generateWeeklyRecipesWithPantryItems();
              },
            ),
          ),
        );
      }
    }
  }
}
