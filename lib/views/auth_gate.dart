import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../controllers/auth_controller.dart';
import 'auth/login_view.dart';
import 'map/map_home_view.dart';

/// Penentu layar awal berdasarkan status otentikasi:
/// - unknown  → splash (sedang cek token)
/// - authenticated   → RootNav (beranda)
/// - unauthenticated → LoginView
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    switch (status) {
      case AuthStatus.authenticated:
        return const MapHomeView();
      case AuthStatus.unauthenticated:
        return const LoginView();
      case AuthStatus.unknown:
        return const _Splash();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore_rounded,
                color: AppColors.purple, size: 56),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}
