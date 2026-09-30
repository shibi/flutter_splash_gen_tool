import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'ui/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SplashGenXApp(themeController: await ThemeController.load()));
}

class SplashGenXApp extends StatelessWidget {
  const SplashGenXApp({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeController ?? ThemeController(),
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Splash GenX',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: const StartScreen(),
        ),
      ),
    );
  }
}
