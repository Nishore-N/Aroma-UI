import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aroma/core/services/auth_service.dart';
import 'package:aroma/ui/screens/home/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return authService.isAuthenticated
        ? HomeScreen(
            phoneNumber: authService.user?.phone ?? '',
          )
        : const LoginScreen();
  }
}
