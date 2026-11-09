import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'services/ads/ad_service.dart';
import 'services/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo AdMob trước khi chạy app; lỗi SDK không được chặn app khởi động
  // (xem AdService.initialize).
  await AdService.instance.initialize();
  runApp(const ProviderScope(child: VoiceMorphApp()));
}

class VoiceMorphApp extends ConsumerWidget {
  const VoiceMorphApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    return MaterialApp.router(
      title: 'VoiceMorph',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Ngôn ngữ theo Settings (mặc định 'vi'); chuỗi lấy từ AppStrings.
      locale: Locale(settings.language),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
