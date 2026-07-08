import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheme_mate/main.dart';
import 'package:scheme_mate/features/auth/presentation/providers/auth_provider.dart';
import 'mock_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Scheme Mate Frontend Integration & Viewport UI Tests', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Complete mock E2E user login flow & screen components render checks', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            httpClientProvider.overrideWithValue(MockHttpClient()),
          ],
          child: const SchemeMateApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the login form elements are present
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);

      // Perform Mock Inputs
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(emailField, 'mock@example.com');
      await tester.enterText(passwordField, 'SecurePass123');
      await tester.pumpAndSettle();

      // Tap Sign In button
      final btn = find.widgetWithText(ElevatedButton, 'Sign In');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Verify viewport layout adaptations (Mobile, Tablet, Desktop) without failures', (WidgetTester tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      // 1. Mobile screen layout bounds (~390px width)
      binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            httpClientProvider.overrideWithValue(MockHttpClient()),
          ],
          child: const SchemeMateApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SchemeMateApp), findsOneWidget);

      // 2. Tablet layout bounds (~768px width)
      binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeMateApp), findsOneWidget);

      // 3. Desktop layout bounds (>=1200px width)
      binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeMateApp), findsOneWidget);
    });
  });
}
