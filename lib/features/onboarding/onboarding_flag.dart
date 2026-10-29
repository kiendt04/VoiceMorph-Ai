import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Cờ "đã xem onboarding": một file trống trong documents. Không thêm
/// package shared_preferences chỉ để lưu một cờ boolean.
class OnboardingFlag {
  static Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}/onboarding_done');
  }

  static Future<bool> isDone() async {
    try {
      // Timeout: trong widget test không có plugin path_provider thật nên
      // channel có thể không bao giờ trả về; không để Splash kẹt ở đây.
      final file = await _file().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => throw TimeoutException('documents dir timeout'),
      );
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDone() async {
    try {
      final file = await _file().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => throw TimeoutException('documents dir timeout'),
      );
      if (!file.existsSync()) await file.create(recursive: true);
    } catch (_) {
      // Không lưu được cờ thì lần sau hiện onboarding lại — không chặn app.
    }
  }
}
