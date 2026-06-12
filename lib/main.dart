import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/feed_controller.dart';
import 'services/api_client.dart';
import 'services/auth_api.dart';
import 'services/auth_storage.dart';
import 'services/post_api.dart';
import 'views/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // untuk format tanggal Indonesia

  // ── Wiring dependency (manual DI): Storage → ApiClient → Api → Controller ──
  final storage = AuthStorage();
  final apiClient = ApiClient(storage);
  final authApi = AuthApi(apiClient, storage);
  final postApi = PostApi(apiClient);

  final authController = AuthController(authApi, storage);
  await authController.bootstrap(); // cek token tersimpan sebelum UI tampil

  runApp(TripmoApp(
    postApi: postApi,
    authController: authController,
  ));
}

class TripmoApp extends StatelessWidget {
  final PostApi postApi;
  final AuthController authController;

  const TripmoApp({
    super.key,
    required this.postApi,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Service layer (dipakai controller per-halaman lewat context.read).
        Provider<PostApi>.value(value: postApi),
        // Controller global.
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<FeedController>(
          create: (_) => FeedController(postApi),
        ),
      ],
      child: MaterialApp(
        title: 'Tripmo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}
