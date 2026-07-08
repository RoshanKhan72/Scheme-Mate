import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized SharedPreferences instance into the Riverpod graph
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SchemeMateApp(),
    ),
  );
}

class SchemeMateApp extends ConsumerWidget {
  const SchemeMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Scheme Mate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follow system preferences
      home: _resolveHomeScreen(authState),
    );
  }

  Widget _resolveHomeScreen(AuthState state) {
    switch (state.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.supervised_user_circle_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const ProfileScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
