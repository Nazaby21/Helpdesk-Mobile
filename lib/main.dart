import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/routes/app_router.dart';
import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = EnvConfig.fromEnvironment();
  final storage = FlutterSecureStorageImpl();

  late final AuthController authController;

  final apiClient = ApiClient(
    config: config,
    storage: storage,
    onSessionExpired: () => authController.handleSessionExpired(),
  );

  authController = AuthController(
    storage: storage,
    apiClient: apiClient,
  );

  await authController.initialize();
  final router = createAppRouter(authController);

  runApp(
    ProviderScope(
      child: HelpdeskApp(router: router),
    ),
  );
}
