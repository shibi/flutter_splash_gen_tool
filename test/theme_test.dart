import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splash_genx/main.dart';
import 'package:splash_genx/theme/app_theme.dart';
import 'package:splash_genx/theme/theme_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('themes use the brand palette', () {
    expect(AppTheme.light.colorScheme.primary, Palette.navy);
    expect(AppTheme.light.colorScheme.secondary, Palette.plum);
    expect(AppTheme.dark.colorScheme.primary, Palette.peach);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('toggle switches between light and dark and is remembered', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(SplashGenXApp(themeController: ThemeController()));
    expect(
      Theme.of(tester.element(find.text('Splash GenX'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Splash GenX'))).brightness,
      Brightness.dark,
    );
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'dark');
    expect((await ThemeController.load()).mode, ThemeMode.dark);
  });
}
