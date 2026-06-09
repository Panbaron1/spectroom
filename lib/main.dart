import 'package:flutter/material.dart';

import 'data/challenge_store.dart';
import 'data/prefs.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChallengeStore.instance.load();
  final seen = await Prefs.seenOnboarding();
  runApp(SpectroomApp(showOnboarding: !seen));
}

class SpectroomApp extends StatelessWidget {
  final bool showOnboarding;
  const SpectroomApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spectroom',
      debugShowCheckedModeBanner: false,
      theme: buildSpectroomTheme(),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
