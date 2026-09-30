import 'package:flutter/material.dart';

import 'ui/start_screen.dart';

void main() {
  runApp(const SplashGenXApp());
}

class SplashGenXApp extends StatelessWidget {
  const SplashGenXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash GenX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const StartScreen(),
    );
  }
}
