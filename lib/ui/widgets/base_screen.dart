import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import 'shimmer_effect.dart';

class BaseScreen extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool showAppBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;

  const BaseScreen({
    Key? key,
    required this.child,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.showAppBar = false,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.bottomNavigationBar,
    this.bottomSheet,
  }) : super(key: key);

  // Helper method to create a page route with consistent transition
  static Route<T> createRoute<T>({
    required Widget page,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  // Custom scroll physics for smooth scrolling
  static const scrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? theme.scaffoldBackgroundColor,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                widget.title ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: widget.extendBodyBehindAppBar 
                  ? Colors.transparent 
                  : theme.appBarTheme.backgroundColor,
              actions: widget.actions,
            )
          : null,
      body: _buildBody(),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      bottomSheet: widget.bottomSheet,
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                widget.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (widget.onRetry != null) ...{
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            },
          ],
        ),
      );
    }

    return widget.child;
  }
}

// Extension for easy navigation
extension NavigationExtension on BuildContext {
  Future<T?> pushScreen<T>(Widget page, {bool fullscreenDialog = false}) {
    return Navigator.of(this).push<T>(
      BaseScreen.createRoute<T>(
        page: page,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
}
