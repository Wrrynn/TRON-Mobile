// Smoke test dasar untuk Tripmo.
//
// Membangun AuthGate dengan AuthController dummy (status unauthenticated)
// lalu memverifikasi layar Login muncul.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tripmo_mobile/config/app_theme.dart';
import 'package:tripmo_mobile/controllers/auth_controller.dart';
import 'package:tripmo_mobile/services/api_client.dart';
import 'package:tripmo_mobile/services/auth_api.dart';
import 'package:tripmo_mobile/services/auth_storage.dart';
import 'package:tripmo_mobile/views/auth_gate.dart';

void main() {
  testWidgets('Menampilkan layar login saat belum login',
      (WidgetTester tester) async {
    final storage = AuthStorage();
    final auth = AuthController(AuthApi(ApiClient(storage), storage), storage)
      ..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.dark, home: const AuthGate()),
      ),
    );

    expect(find.text('Tripmo'), findsWidgets);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
