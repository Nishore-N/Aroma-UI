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
  bool isEmpty = true;

  @override
  void initState() {
    super.initState();
    _checkPantry();
  }

  Future<void> _checkPantry() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = authService.user?.mobile_no;
      
      // First try to get remote pantry items
      final remoteItems = await _service.fetchPantryItems(userId: userId);
      isEmpty = remoteItems.isEmpty;
      
      // If remote is empty, check local pantry state as fallback
      if (isEmpty && mounted) {
        final pantryState = Provider.of<PantryState>(context, listen: false);
        await pantryState.loadPantry();
        final localItems = pantryState.items;
        isEmpty = localItems.isEmpty;
        debugPrint("📦 Remote pantry empty, checking local: ${localItems.length} items");
      }
    } catch (e) {
      debugPrint("❌ Pantry root error: $e");
      
      // Fallback to local pantry state
      if (mounted) {
        try {
          final pantryState = Provider.of<PantryState>(context, listen: false);
          await pantryState.loadPantry();
          final localItems = pantryState.items;
          isEmpty = localItems.isEmpty;
          debugPrint("📦 Using local pantry fallback: ${localItems.length} items");
        } catch (localError) {
          debugPrint("❌ Local pantry fallback failed: $localError");
          isEmpty = true;
        }
      }
    }

    setState(() => loading = false);
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
