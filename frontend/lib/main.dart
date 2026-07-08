import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/profile_edit_screen.dart';
import 'features/notifications/presentation/screens/notification_list_screen.dart';
import 'features/schemes/presentation/screens/scheme_list_screen.dart';
import 'features/schemes/presentation/screens/scheme_detail_screen.dart';
import 'features/schemes/presentation/screens/admin_schemes_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = ref.read(authProvider);
          switch (authState.status) {
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
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/schemes',
        builder: (context, state) => const SchemeListScreen(),
      ),
      GoRoute(
        path: '/admin-schemes',
        builder: (context, state) => const AdminSchemesScreen(),
      ),
      GoRoute(
        path: '/scheme-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SchemeDetailScreen(schemeId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final location = state.uri.path;

      final isLoggingIn = location == '/login' || location == '/register';

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      if (status != AuthStatus.authenticated) {
        if (!isLoggingIn) {
          return '/login';
        }
      } else {
        if (isLoggingIn || location == '/') {
          return '/profile';
        }
      }

      return null;
    },
  );
});

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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Scheme Mate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follow system preferences
      routerConfig: router,
    );
  }
}
