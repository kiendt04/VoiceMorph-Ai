import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';

/// Màn hình giữ chỗ cho các route chưa dựng ở Giai đoạn 1.
/// Mỗi màn hình thật sẽ thay thế một PlaceholderScreen này, không đổi path.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(đang chờ dựng ở Giai đoạn 1)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Router của app (go_router). Home là '/' để màn hình tạm mở lên ngay.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const PlaceholderScreen(title: 'Splash'),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/record',
      builder: (context, state) => const PlaceholderScreen(title: 'Recording'),
    ),
    GoRoute(
      path: '/effects',
      builder: (context, state) => const PlaceholderScreen(title: 'ChooseEffect'),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) => const PlaceholderScreen(title: 'FineTune'),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const PlaceholderScreen(title: 'Result'),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const PlaceholderScreen(title: 'Library'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PlaceholderScreen(title: 'Paywall'),
    ),
  ],
);
