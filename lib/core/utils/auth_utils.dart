import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';

Future<void> handleAuthResponse({
  required BuildContext context,
  required Future<dynamic> Function() authCall,
  required VoidCallback onSuccess,
  required Function(String) onError,
}) async {
  try {
    final response = await authCall();
    if (!context.mounted) return;

    if (response?.success == true) {
      // Refresh auth state
      await Provider.of<AuthService>(context, listen: false).initialize();
      onSuccess();
    } else {
      onError(response?.message ?? 'An unknown error occurred');
    }
  } catch (e) {
    if (context.mounted) {
      onError('An error occurred. Please try again.');
    }
  }
}
