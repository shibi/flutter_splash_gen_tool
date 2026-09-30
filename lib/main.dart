import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/editor_state.dart';
import 'ui/start_screen.dart';

void main() {
  runApp(const SplashGenXApp());
}

class SplashGenXApp extends StatelessWidget {
  const SplashGenXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(),
      child: MaterialApp(
        title: 'Splash GenX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: const StartScreen(),
      ),
    );
  }
}
