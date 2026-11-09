import 'dart:io';

import 'package:flutter/foundation.dart';

/// Cấu hình AdMob: App ID và Ad Unit ID theo nền tảng.
///
/// Debug/profile luôn dùng ID test chính thức của Google, release tự
/// động dùng ID thật ([useTestAds] = !kReleaseMode) — không cần đổi tay
/// trước khi release, và tuyệt đối không dùng ID thật trong bản debug,
/// vì traffic test có thể làm tài khoản AdMob bị hạn chế.
///
/// App ID thật trên Android đã khai trong AndroidManifest.xml.
/// iOS chưa có app/Ad Unit thật trên AdMob nên [production] iOS vẫn để
/// trống — bản release iOS sẽ tự tắt quảng cáo cho tới khi sếp tạo app
/// iOS trên AdMob và điền ID vào đây.
class AdConfig {
  /// true ở debug/profile (dùng ID test), false ở release (dùng ID thật).
  static const bool useTestAds = !kReleaseMode;

  static const _testAppIds = {
    'android': 'ca-app-pub-3940256099942544~3347511713',
    'ios': 'ca-app-pub-3940256099942544~1458002511',
  };

  /// App ID thật từ AdMob (sếp tạo ngày 2026-11-09).
  /// Android: ca-app-pub-2282607783775102~1502719044
  static const _productionAppIds = {
    'android': 'ca-app-pub-2282607783775102~1502719044',
    'ios': '',
  };

  /// ID test chính thức của Google cho từng định dạng.
  static const _testAdUnits = {
    'android': {
      'banner': 'ca-app-pub-3940256099942544/6300978111',
      'interstitial': 'ca-app-pub-3940256099942544/1033173712',
      'rewarded': 'ca-app-pub-3940256099942544/5224354917',
    },
    'ios': {
      'banner': 'ca-app-pub-3940256099942544/2934735716',
      'interstitial': 'ca-app-pub-3940256099942544/4411468910',
      'rewarded': 'ca-app-pub-3940256099942544/1712485313',
    },
  };

  /// Ad Unit ID thật từ AdMob (sếp tạo ngày 2026-11-09, Android).
  /// Banner: ca-app-pub-2282607783775102/2295045638
  /// Interstitial: ca-app-pub-2282607783775102/6306267824
  /// Rewarded: ca-app-pub-2282607783775102/5966697338
  static const _productionAdUnits = {
    'android': {
      'banner': 'ca-app-pub-2282607783775102/2295045638',
      'interstitial': 'ca-app-pub-2282607783775102/6306267824',
      'rewarded': 'ca-app-pub-2282607783775102/5966697338',
    },
    'ios': {'banner': '', 'interstitial': '', 'rewarded': ''},
  };

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  static String get appId =>
      (useTestAds ? _testAppIds : _productionAppIds)[_platform]!;

  static String bannerAdUnitId() =>
      (useTestAds ? _testAdUnits : _productionAdUnits)[_platform]!['banner']!;

  static String interstitialAdUnitId() => (useTestAds ? _testAdUnits : _productionAdUnits)[_platform]!['interstitial']!;

  static String rewardedAdUnitId() =>
      (useTestAds ? _testAdUnits : _productionAdUnits)[_platform]!['rewarded']!;
}
