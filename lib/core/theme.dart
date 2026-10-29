import 'package:flutter/material.dart';

/// Theme Material 3 rút từ Figma: tông tối hiện đại, màu nhấn tím/xanh,
/// bo góc lớn cho nút và card. Giai đoạn 0 chỉ cần theme chung; tinh chỉnh
/// theo đúng token Figma ở Giai đoạn 1 khi dựng đủ màn hình.
class AppTheme {
  static const _accent = Color(0xFF7C6CFF);
  static const _accentSecondary = Color(0xFF38BDF8);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(secondary: _accentSecondary),
      scaffoldBackgroundColor: const Color(0xFF12121A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12121A),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
