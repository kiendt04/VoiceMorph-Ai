import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'services/ads/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo AdMob trước khi chạy app; lỗi SDK không được chặn app khởi động
  // (xem AdService.initialize).
  await AdService.instance.initialize();
  runApp(const ProviderScope(child: VoiceMorphApp()));
}

class VoiceMorphApp extends StatelessWidget {
  const VoiceMorphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VoiceMorph',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
