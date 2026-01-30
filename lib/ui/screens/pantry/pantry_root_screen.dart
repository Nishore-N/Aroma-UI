import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pantry_list_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../state/pantry_state.dart';
import 'pantry_empty_screen.dart';
import 'pantry_home_screen.dart';

class PantryRootScreen extends StatefulWidget {
  const PantryRootScreen({super.key});

  @override
  State<PantryRootScreen> createState() => _PantryRootScreenState();
}

class _PantryRootScreenState extends State<PantryRootScreen> {
  final PantryListService _service = PantryListService();

  bool loading = true;


  @override
  void initState() {
    super.initState();
    _checkPantry();
  }

  Future<void> _checkPantry() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = authService.user?.mobile_no;
      
      // Get remote pantry items
      final remoteItems = await _service.fetchPantryItems(userId: userId);
      
      if (mounted) {
        final pantryState = Provider.of<PantryState>(context, listen: false);
        // Always update state with what we got (even if empty) to ensure sync
        await pantryState.setRemoteItems(remoteItems);
      }
    } catch (e) {
      debugPrint("❌ Pantry root error: $e");
      // No local fallback as requested
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<PantryState>(
      builder: (context, pantryState, child) {
        return pantryState.items.isEmpty
            ? const PantryEmptyScreen()
            : const PantryHomeScreen();
      },
    );
  }
}
