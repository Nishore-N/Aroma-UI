import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../data/models/recipe_model.dart';

import '../../../core/services/auth_service.dart';
import '../../../state/home_provider.dart';
import '../../widgets/explore_popular_choice_card.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/custom_search_icon.dart';
import '../add_ingredients/ingredient_entry_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../calendar/calendar_empty_screen.dart';
import '../pantry/pantry_empty_screen.dart';
import '../pantry/pantry_root_screen.dart';
import '../../../core/enums/scan_mode.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../../../widgets/primary_button.dart';
import '../../widgets/web_banner.dart';
import 'generate_recipe_screen.dart';
import 'pantry_selection_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notification_screen.dart';

class SpringScrollPhysics extends ScrollPhysics {
  const SpringScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SpringScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SpringScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Apply spring resistance when overscrolling
    if (position.outOfRange) {
      final double overscrollPastStart = math.max(0.0, position.minScrollExtent - position.pixels);
      final double overscrollPastEnd = math.max(0.0, position.pixels - position.maxScrollExtent);
      final double overscrollDistance = overscrollPastStart > 0 ? overscrollPastStart : overscrollPastEnd;
      final double stiffness = 0.15; // Spring stiffness
      final double resistance = stiffness * overscrollDistance;
      return offset * (1.0 - resistance);
    }
    return offset;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return true;
  }

  @override
  double carryMomentumVelocity(ScrollMetrics position, double velocity) {
    // Spring-like momentum with gentle deceleration
    return velocity * 0.88;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) {
      // Create spring simulation when out of range
      return _SpringSimulation(
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        spring: const SpringDescription(
          mass: 1.0,
          stiffness: 200.0,
          damping: 12.0,
        ),
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _SpringSimulation extends Simulation {
  final double position;
  final double velocity;
  final double leadingExtent;
  final double trailingExtent;
  final SpringDescription spring;

  _SpringSimulation({
    required this.position,
    required this.velocity,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.spring,
  });

  late final SpringSimulation _springSimulation;
  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;
    
    final double target = position < leadingExtent 
        ? leadingExtent 
        : position > trailingExtent 
            ? trailingExtent 
            : position;
    
    _springSimulation = SpringSimulation(
      spring,
      position,
      target,
      velocity * 0.3, // Reduce velocity for gentler spring
    );
    _isInitialized = true;
  }

  @override
  double x(double time) {
    _initialize();
    return _springSimulation.x(time);
  }

  @override
  double dx(double time) {
    _initialize();
    return _springSimulation.dx(time);
  }

  @override
  bool isDone(double time) {
    _initialize();
    return _springSimulation.isDone(time);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.phoneNumber = '',
  });

  final String phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _buttonController;
  late final Animation<double> _buttonAnimation;
  late final ScrollController _scrollController;
  late final AnimationController _autoScrollController;
  late final AnimationController _pageIndicatorController;
  late final Animation<double> _pageIndicatorAnimation;
  late final Timer _autoScrollTimer;
  
  double _currentPage = 0.0;
  final double _cardAspectRatio = 0.85;
  final double _cardPadding = 20.0;
  final Set<String> _expandedCuisines = {}; // Tracks which cuisines are expanded
  // bool _showAllCategories = false; // Deprecated
  int _visibleRecipeCount = 2;
  bool _isUserScrolling = false;
  String _selectedCuisine = 'Any';
  
  final List<String> _cuisineOptions = [
    "Any",
    "Indian",
    "Mexican",
    "Italian",
    "American",
    "Chinese",
    "Thai",
    "Mediterranean",
    "French",
    "Korean",
    "Japanese"
  ];

  Future<void> _loadShowAllPreference() async {
    // Don't load the preference on app start to always show 2 recipes initially
    // The preference will only be used if the user navigates away and comes back
    // in the same session
  }

  Future<void> _saveShowAllPreference(bool showAll) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_all_categories', showAll);
  }

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initialized with phone number: ${widget.phoneNumber}');
    
    // Initial fetch for "Any" cuisine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).loadExploreRecipes(cuisine: 'Any');
    });

    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
    
    _scrollController = ScrollController(
      keepScrollOffset: true,
    )..addListener(_onScrollChanged);
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOutSine,
    ));
    
    _pageIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _pageIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageIndicatorController,
      curve: Curves.easeOutCubic,
    ));
    
    _autoScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _buttonController.repeat(reverse: true);
    _loadShowAllPreference();
    _startAutoScroll();
  }

  // ... (keeping existing methods until build)


  
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isUserScrolling && mounted) {
        final provider = Provider.of<HomeProvider>(context, listen: false);
        if (provider.recipes.isNotEmpty) {
          final nextPage = (_currentPage.toInt() + 1) % provider.recipes.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }
  
  void _onUserScrollStart() {
    _isUserScrolling = true;
    // Reset auto-scroll timer after user interaction
    _autoScrollTimer?.cancel();
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _isUserScrolling = false;
      }
    });
  }
  
  void _onScrollChanged() {
    // Keep the show all state persistent by removing the auto-collapse on scroll to top
    // The state will only change when explicitly toggled by the user
  }
  
  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _autoScrollController.dispose();
    _pageController.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _buttonController.dispose();
    _pageIndicatorController.dispose();
    super.dispose();
  }

  // Custom scroll physics for smooth scrolling
  final _scrollPhysics = const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  Widget _buildRecipeCarousel() {
    return SizedBox(
      height: 360.0,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (!_pageController.position.isScrollingNotifier.value) {
              _pageController.position.isScrollingNotifier.value = true;
            }
          } else if (notification is ScrollEndNotification) {
            _pageController.position.isScrollingNotifier.value = false;
          }
          return true;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: Provider.of<HomeProvider>(context, listen: false).recipes.length,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padEnds: false,
          onPageChanged: (int index) {
            setState(() {
              _currentPage = index.toDouble();
            });
            _pageIndicatorController.forward().then((_) {
              _pageIndicatorController.reset();
            });
          },
          itemBuilder: (context, index) {
            return _buildRecipeCard(Provider.of<HomeProvider>(context, listen: false).recipes[index], index);
          },
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pageIndicatorAnimation,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                Provider.of<HomeProvider>(context).bannerRecipes.length,
                (index) {
                  final bool isActive = _currentPage.round() == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: isActive 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300],
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.4),
                                blurRadius: 12.0,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe, int index) {
    final double pageOffset = index - _currentPage;
    final double scaleFactor = 0.9 + (0.1 * (1 - pageOffset.abs()));
    final double opacity = (1 - (pageOffset.abs() * 0.5)).clamp(0.2, 1.0);
    
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final double rotation = pageOffset * 0.03;
        final double offsetX = pageOffset * 30;
        
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(rotation)
            ..scale(scaleFactor),
          alignment: pageOffset > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(offsetX, 0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToRecipeDetail(recipe),
        child: Hero(
          tag: 'recipe_${recipe.id}',
          child: RecipeCard(
            recipe: recipe,
          ),
        ),
      ),
    );
  }

  void _navigateToRecipeDetail(RecipeModel recipe) {
    // Use the full backend data if available, otherwise create basic structure
    final fullRecipeData = recipe.fullRecipeData ?? {
      'description': recipe.description ?? '',
      'nutrition': {
        'calories': recipe.calories,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      },
      'cooking_steps': recipe.instructions.map((instruction) => {
        'instruction': instruction,
        'ingredients': [],
        'tips': [],
      }).toList(),
      'tags': {
        'cookware': [],
      },
      'ingredients': recipe.ingredients.map((ingredient) => {
        'item': ingredient,
        'quantity': '1',
      }).toList(),
    };

    // Convert string ingredients to Map format for RecipeDetailScreen
    final rawIngredients = fullRecipeData['ingredients'] as List<dynamic>?;
    final List<Map<String, dynamic>> ingredientMaps = [];

    if (rawIngredients != null) {
      for (var ing in rawIngredients) {
        if (ing is Map<String, dynamic>) {
          ingredientMaps.add(ing);
        } else if (ing is String) {
          ingredientMaps.add({
            'item': ing,
            'quantity': '1',
          });
        }
      }
    }

    if (ingredientMaps.isEmpty && recipe.ingredients.isNotEmpty) {
       ingredientMaps.addAll(recipe.ingredients.map((ingredient) => {
          'item': ingredient,
          'quantity': '1',
        }));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          image: recipe.image,
          title: recipe.title,
          ingredients: ingredientMaps,
          cuisine: recipe.cuisine,
          cookTime: recipe.cookTime,
          servings: recipe.servings,
          fullRecipeData: fullRecipeData,
        ),
      ),
    );
  }

  Future<void> _loadMoreRecipes() async {
    // Implement your recipe loading logic here
    // For example:
    // await Provider.of<HomeProvider>(context, listen: false).loadMoreRecipes();
  }

  Widget _buildShowMoreButton() {
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        final totalRecipes = provider.recipes.length;
        return AnimatedBuilder(
          animation: _buttonAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _buttonAnimation.value * 4 - 2), // Subtle bounce effect
              child: child,
            );
          },
          child: MouseRegion(
            onEnter: (_) => _buttonController.stop(),
            onExit: (_) => _buttonController.repeat(reverse: true),
            child: GestureDetector(
              onTapDown: (_) => _buttonController.stop(),
              onTapCancel: () => _buttonController.repeat(reverse: true),
              onTap: () {
                _buttonController.repeat(reverse: true);
                setState(() {
                  _expandedCuisines.add(_selectedCuisine);
                  _visibleRecipeCount = totalRecipes;
                });
                // _saveShowAllPreference(true);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                height: 56.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _visibleRecipeCount >= totalRecipes
                          ? 'All Recipes Shown'
                          : 'Show More',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _buttonAnimation.value * 0.2 - 0.1, // Subtle wiggle
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug prints removed to reduce noise
    final authService = Provider.of<AuthService>(context, listen: true);
    final theme = Theme.of(context);
    
    if (!authService.isAuthenticated) {
      // User not authenticated, redirecting to login...
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Consumer<HomeProvider>(
      builder: (BuildContext context, HomeProvider provider, _) {
        if (provider.isLoading && provider.recipes.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (provider.error != null && provider.recipes.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading recipes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadRecipes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Carousel Recipes from Banner API
        final carouselRecipes = provider.bannerRecipes;
        
        // Explore Recipes from API (via Provider)
        final exploreRecipes = provider.exploreRecipes;
        
        // Filter explore recipes based on selection
        final filteredExploreRecipes = _selectedCuisine == 'Any' 
            ? exploreRecipes 
            : exploreRecipes.where((r) => r.cuisine == _selectedCuisine).toList();
            
        final bool isExpanded = _expandedCuisines.contains(_selectedCuisine);
        final displayRecipes = isExpanded
            ? filteredExploreRecipes 
            : filteredExploreRecipes.take(2).toList();
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.loadBannerRecipes();
                await provider.loadExploreRecipes(cuisine: _selectedCuisine);
              },
              color: const Color(0xFFFF724C),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFFFFBF6),
                      Color(0xFFFFF3E6),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: SpringScrollPhysics(),
                    ),
                    cacheExtent: 500.0,
                    semanticChildCount: exploreRecipes.length,
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 8),
                          RepaintBoundary(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.headlineMedium,
                                      children: [
                                        const TextSpan(text: 'Welcome '),
                                        const TextSpan(
                                          text: '👋',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                        TextSpan(
                                          text: '\n${authService.user?.name ?? 'Guest'}',
                                          style: TextStyle(
                                            color: const Color(0xFFFF4500),
                                            fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize != null 
                                                ? Theme.of(context).textTheme.headlineMedium!.fontSize! * 1.2 
                                                : 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: widget.phoneNumber.isEmpty ? '' : ' ${widget.phoneNumber.length > 5 ? widget.phoneNumber.replaceRange(0, 5, '*') : widget.phoneNumber}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const PantryRootScreen(),
                                            ),
                                          );
                                        },
                                        icon: SvgPicture.asset(
                                          'assets/images/pantry_icon.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const NotificationScreen(),
                                            ),
                                          );
                                        },
                                        icon: SvgPicture.asset(
                                          'assets/images/notification_icon.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (BuildContext context) {
                              final double screenWidth =
                                  MediaQuery.of(context).size.width;
                              final double cardWidth =
                                  screenWidth * _pageController.viewportFraction;
                              final double cardHeight =
                                  cardWidth * 3 / 2; // 3:2 ratio for old card design

                              return SizedBox(
                                height: cardHeight,
                                child: GestureDetector(
                                  onPanStart: (_) => _onUserScrollStart(),
                                  child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: carouselRecipes.length,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: SpringScrollPhysics(),
                                  ),
                                  pageSnapping: true,
                                  padEnds: false,
                                  onPageChanged: (int index) {
                                    setState(() {
                                      _currentPage = index.toDouble();
                                    });
                                  },
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final recipe = carouselRecipes[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 12),
                                      child: AnimatedScale(
                                        duration: const Duration(
                                            milliseconds: 150),
                                        curve: Curves.easeOutCubic,
                                        scale: index == _currentPage
                                            ? 1.0
                                            : 0.96,
                                        child: SizedBox(
                                          width: cardWidth,
                                          height: cardHeight,
                                          child: RecipeCard(
                                            recipe: recipe,
                                            isActive: index == _currentPage,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  ),
                                ),
                              );
                            },
                          ),
                          RepaintBoundary(
                            child: _buildPageIndicator(),
                          ),
                          const SizedBox(height: 16),
                          const WebBanner(),
                          const SizedBox(height: 24),
                          RepaintBoundary(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Explore popular recipes',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SearchScreen(),
                                      ),
                                    );
                                  },
                                  icon: const CustomSearchIcon(size: 32),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Preferred Cuisine',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Pull to refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _cuisineOptions.map((cuisine) {
                                final isSelected = _selectedCuisine == cuisine;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      print('🔴 DEBUG: Cuisine Grid Item Tapped: $cuisine');
                                      setState(() {
                                        _selectedCuisine = cuisine;
                                        // _showAllCategories = false; // Removed to persist state as requested
                                      });
                                      
                                      // Fetch recipes for the selected cuisine
                                      print('🔴 DEBUG: Calling Provider.loadExploreRecipes for $cuisine');
                                      Provider.of<HomeProvider>(context, listen: false)
                                          .loadExploreRecipes(cuisine: cuisine);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFF724C)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            cuisine,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.black87,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 0),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: displayRecipes.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (index >= displayRecipes.length) {
                            return const SizedBox.shrink();
                          }

                          final recipe = displayRecipes[index];

                          return RepaintBoundary(
                            child: ExplorePopularChoiceCard(
                              recipe: recipe,
                              isLeftCard: index.isEven,
                            ),
                          );
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: exploreRecipes.length <= 2 || _expandedCuisines.contains(_selectedCuisine)
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  setState(() {
                                    _expandedCuisines.add(_selectedCuisine);
                                  });
                                  
                                  // Auto-scroll to bottom after showing all recipes
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutCubic,
                                    );
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.35),
                                    width: 1.1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const <Widget>[
                                    Text('Show More'),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/images/home_icon.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(Color(0xFFFC6E3C), BlendMode.srcIn),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/images/search_icon.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(
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
                IconButton(
                  onPressed: () {
                    print("🔍 DEBUG: Calendar icon clicked - navigating to CalendarEmptyScreen");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarEmptyScreen(),
                      ),
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/images/calendar_icon.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => ProfileScreen(
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/images/profile_icon.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}