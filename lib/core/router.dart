import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/editor/editor_screen.dart';
import '../features/effects/effects_screen.dart';
import '../features/flow/flow_args.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/processing/processing_screen.dart';
import '../features/record/record_screen.dart';
import '../features/result/result_screen.dart';

/// Màn hình giữ chỗ cho các route chưa dựng (Settings, Paywall — Giai đoạn 3).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(sẽ dựng ở giai đoạn sau)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Router của app (go_router). Dữ liệu luồng đổi giọng truyền qua `extra`
/// (xem flow_args.dart); route nào nhận sai kiểu extra sẽ hiện màn báo lỗi
/// thay vì crash.
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/record',
      builder: (context, state) => const RecordScreen(),
    ),
    GoRoute(
      path: '/effects',
      builder: (context, state) => EffectsScreen(
        args: state.extra as EffectsArgs?,
      ),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final args = state.extra as EditorArgs?;
        if (args == null) {
          return const PlaceholderScreen(title: 'Thiếu dữ liệu FineTune');
        }
        return EditorScreen(args: args);
      },
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) {
        final args = state.extra as ProcessingArgs?;
        if (args == null) {
          return const PlaceholderScreen(title: 'Thiếu dữ liệu xử lý');
        }
        return ProcessingScreen(args: args);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final args = state.extra as ResultArgs?;
        if (args == null) {
          return const PlaceholderScreen(title: 'Thiếu dữ liệu kết quả');
        }
        return ResultScreen(args: args);
      },
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
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
