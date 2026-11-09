import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trạng thái cài đặt lưu trên máy (Giai đoạn 3, local-only).
///
/// Mọi thay đổi đều ghi xuống SharedPreferences ngay. Lỗi đọc/ghi
/// (kể cả trong widget test không có plugin thật) đều nuốt gọn và giữ
/// giá trị mặc định, không được làm crash app.
class SettingsState {
  const SettingsState({
    this.themeMode = 'dark',
    this.defaultExportFormat = 'wav',
    this.defaultExportBitrate = 192,
    this.language = 'vi',
    this.responsibleUseAccepted = false,
    this.renderSuccessCount = 0,
    this.interstitialLastShownMs = 0,
    this.interstitialShownTodayCount = 0,
    this.interstitialShownDate = '',
    this.rewardedUnlocks = const {},
  });

  /// 'system' | 'dark' | 'light'. Mặc định 'dark' để giữ đúng diện mạo
  /// hiện tại của app (trước Giai đoạn 3 app chỉ có theme tối).
  final String themeMode;

  /// Định dạng xuất mặc định ở màn Result: 'wav' | 'mp3' | 'm4a'.
  final String defaultExportFormat;

  /// Bitrate mặc định cho MP3/M4A (kbps). Bị khóa khi chọn WAV.
  final int defaultExportBitrate;

  /// 'vi' | 'en'.
  final String language;

  final bool responsibleUseAccepted;

  /// Số lần render thành công tích lũy (dùng cho cổng interstitial).
  final int renderSuccessCount;

  final int interstitialLastShownMs;
  final int interstitialShownTodayCount;
  final String interstitialShownDate;

  /// presetId -> thời điểm hết hạn mở tạm bằng rewarded (epoch ms).
  final Map<String, int> rewardedUnlocks;

  SettingsState copyWith({
    String? themeMode,
    String? defaultExportFormat,
    int? defaultExportBitrate,
    String? language,
    bool? responsibleUseAccepted,
    int? renderSuccessCount,
    int? interstitialLastShownMs,
    int? interstitialShownTodayCount,
    String? interstitialShownDate,
    Map<String, int>? rewardedUnlocks,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      defaultExportBitrate: defaultExportBitrate ?? this.defaultExportBitrate,
      language: language ?? this.language,
      responsibleUseAccepted:
          responsibleUseAccepted ?? this.responsibleUseAccepted,
      renderSuccessCount: renderSuccessCount ?? this.renderSuccessCount,
      interstitialLastShownMs:
          interstitialLastShownMs ?? this.interstitialLastShownMs,
      interstitialShownTodayCount:
          interstitialShownTodayCount ?? this.interstitialShownTodayCount,
      interstitialShownDate:
          interstitialShownDate ?? this.interstitialShownDate,
      rewardedUnlocks: rewardedUnlocks ?? this.rewardedUnlocks,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _kThemeMode = 'themeMode';
  static const _kExportFormat = 'defaultExportFormat';
  static const _kExportBitrate = 'defaultExportBitrate';
  static const _kLanguage = 'language';
  static const _kResponsibleUse = 'responsibleUseAccepted';
  static const _kRenderCount = 'renderSuccessCount';
  static const _kInterLast = 'interstitialLastShownMs';
  static const _kInterTodayCount = 'interstitialShownTodayCount';
  static const _kInterDate = 'interstitialShownDate';
  static const _kRewarded = 'rewardedUnlocks';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRewarded);
      final unlocks = <String, int>{};
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          final v = e.value;
          if (v is int) unlocks[e.key] = v;
        }
      }
      state = state.copyWith(
        themeMode: prefs.getString(_kThemeMode) ?? state.themeMode,
        defaultExportFormat:
            prefs.getString(_kExportFormat) ?? state.defaultExportFormat,
        defaultExportBitrate:
            prefs.getInt(_kExportBitrate) ?? state.defaultExportBitrate,
        language: prefs.getString(_kLanguage) ?? state.language,
        responsibleUseAccepted:
            prefs.getBool(_kResponsibleUse) ?? state.responsibleUseAccepted,
        renderSuccessCount:
            prefs.getInt(_kRenderCount) ?? state.renderSuccessCount,
        interstitialLastShownMs:
            prefs.getInt(_kInterLast) ?? state.interstitialLastShownMs,
        interstitialShownTodayCount:
            prefs.getInt(_kInterTodayCount) ?? state.interstitialShownTodayCount,
        interstitialShownDate:
            prefs.getString(_kInterDate) ?? state.interstitialShownDate,
        rewardedUnlocks: unlocks,
      );
    } catch (_) {
      // Giữ mặc định.
    }
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveString(_kThemeMode, mode);
  }

  Future<void> setDefaultExportFormat(String format) async {
    state = state.copyWith(defaultExportFormat: format);
    await _saveString(_kExportFormat, format);
  }

  Future<void> setDefaultExportBitrate(int kbps) async {
    state = state.copyWith(defaultExportBitrate: kbps);
    await _saveInt(_kExportBitrate, kbps);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveString(_kLanguage, language);
  }

  Future<void> setResponsibleUseAccepted(bool accepted) async {
    state = state.copyWith(responsibleUseAccepted: accepted);
    await _saveBool(_kResponsibleUse, accepted);
  }

  Future<void> incrementRenderSuccessCount() async {
    final next = state.renderSuccessCount + 1;
    state = state.copyWith(renderSuccessCount: next);
    await _saveInt(_kRenderCount, next);
  }

  Future<void> recordInterstitialShown(DateTime now) async {
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final count =
        state.interstitialShownDate == today ? state.interstitialShownTodayCount + 1 : 1;
    state = state.copyWith(
      interstitialLastShownMs: now.millisecondsSinceEpoch,
      interstitialShownTodayCount: count,
      interstitialShownDate: today,
    );
    await _saveInt(_kInterLast, now.millisecondsSinceEpoch);
    await _saveInt(_kInterTodayCount, count);
    await _saveString(_kInterDate, today);
  }

  Future<void> grantRewardedUnlock(String presetId, int expiryMs) async {
    final next = Map<String, int>.from(state.rewardedUnlocks)
      ..[presetId] = expiryMs;
    state = state.copyWith(rewardedUnlocks: next);
    await _saveString(_kRewarded, jsonEncode(next));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
