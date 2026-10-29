import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_flag.dart';

/// Màn hình chờ ngắn: quyết định đi Onboarding (lần đầu) hay Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final done = await OnboardingFlag.isDone();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go(done ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audiotrack, size: 64),
            SizedBox(height: 16),
            Text(
              'VoiceMorph',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
