import 'dart:io';

/// Cấu hình AdMob: App ID và Ad Unit ID theo nền tảng.
///
/// Khi dev luôn dùng ID test chính thức của Google. Chỉ đổi [useTestAds]
/// thành false VÀ điền ID thật vào [production] trước khi release — tuyệt
/// đối không dùng ID thật trong bản debug, vì traffic test có thể làm
/// tài khoản AdMob bị hạn chế.
///
/// App ID test cũng phải khớp với meta-data trong AndroidManifest.xml
/// và key GADApplicationIdentifier trong Info.plist (đã khai sẵn).
class AdConfig {
  /// Đổi thành false khi đã có tài khoản AdMob thật và ID thật.
  static const bool useTestAds = true;

  static const _testAppIds = {
    'android': 'ca-app-pub-3940256099942544~3347511713',
    'ios': 'ca-app-pub-3940256099942544~1458002511',
  };

  /// Điền App ID thật từ AdMob vào đây trước khi release.
  static const _productionAppIds = {'android': '', 'ios': ''};

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

  /// Điền Ad Unit ID thật từ AdMob vào đây trước khi release.
  static const _productionAdUnits = {
    'android': {'banner': '', 'interstitial': '', 'rewarded': ''},
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
