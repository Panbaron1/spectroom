import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/challenge_store.dart';
import 'data/lang_store.dart';
import 'data/prefs.dart';
import 'data/schedule_store.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  try { await NotificationService.instance.init(); } catch (_) {}
  await Future.wait([
    ChallengeStore.instance.load(),
    LangStore.instance.load(),
    ScheduleStore.instance.load(),
  ]);
  try { await ScheduleStore.instance.rescheduleAll(); } catch (_) {}
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
      builder: (context, child) {
        // Clamp the OS font-scale so large accessibility settings can't
        // overflow fixed layouts. 1.0–1.3 keeps text readable but bounded.
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child!,
        );
      },
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
