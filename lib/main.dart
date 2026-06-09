import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/challenge_store.dart';
import 'data/lang_store.dart';
import 'data/prefs.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Future.wait([
    ChallengeStore.instance.load(),
    LangStore.instance.load(),
  ]);
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
