import 'package:flutter/material.dart';

import 'data/challenge_store.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChallengeStore.instance.load();
  runApp(const SpectroomApp());
}

class SpectroomApp extends StatelessWidget {
  const SpectroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spectroom',
      debugShowCheckedModeBanner: false,
      theme: buildSpectroomTheme(),
      home: const HomeScreen(),
    );
  }
}
