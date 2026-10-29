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
      return (await _file()).existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDone() async {
    try {
      final file = await _file();
      if (!file.existsSync()) await file.create(recursive: true);
    } catch (_) {
      // Không lưu được cờ thì lần sau hiện onboarding lại — không chặn app.
    }
  }
}
