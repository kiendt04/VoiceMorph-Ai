import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Điểm duy nhất trong app được phép chạm vào SDK AdMob.
///
/// - [initialize] phải được gọi trong main() trước runApp.
/// - Mọi lỗi load/hiện quảng cáo đều được nuốt gọn và trả về null/false:
///   không mạng, không có quảng cáo, SDK chưa sẵn sàng đều không được
///   làm crash app.
/// - Quảng cáo chỉ hiện khi [AdConfig.useTestAds] hoặc ID thật đã được
///   điền; nếu ID rỗng thì coi như quảng cáo đang tắt.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // Quảng cáo là tính năng phụ: SDK lỗi thì app vẫn chạy không quảng cáo.
      _initialized = false;
    }
  }

  bool get _hasAdUnits =>
      AdConfig.bannerAdUnitId().isNotEmpty ||
      AdConfig.interstitialAdUnitId().isNotEmpty ||
      AdConfig.rewardedAdUnitId().isNotEmpty;

  /// Nạp một banner. Trả về null khi không nạp được (gọi widget hiển thị
  /// gì cũng được, hoặc không hiển thị gì).
  Future<BannerAd?> loadBanner() async {
    if (!_initialized || AdConfig.bannerAdUnitId().isEmpty) return null;
    final completer = Completer<BannerAd?>();
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdConfig.bannerAdUnitId(),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    try {
      await ad.load();
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  /// Nạp rồi hiện interstitial ngay. Trả về false khi không hiện được.
  Future<bool> showInterstitial() async {
    if (!_initialized || AdConfig.interstitialAdUnitId().isEmpty) return false;
    final completer = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete(true);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete(false);
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  /// Hiện rewarded. Trả về true chỉ khi người dùng xem xong và nhận thưởng.
  /// Dùng cho "xem quảng cáo để mở tạm hiệu ứng PRO" ở Giai đoạn 3.
  Future<bool> showRewarded() async {
    if (!_initialized || AdConfig.rewardedAdUnitId().isEmpty) return false;
    var earned = false;
    final completer = Completer<bool>();
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete(earned);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete(false);
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) {
                earned = true;
              },
            );
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  /// Có quảng cáo để hiện hay không (dùng để ẩn hẳn khu vực banner khi tắt).
  bool get adsEnabled => _initialized && _hasAdUnits;
}

/// Widget banner tự nạp và tự dọn dẹp. Khi không nạp được quảng cáo thì
/// hiển thị một hộp giữ chỗ nhỏ (chỉ ở bản dev) thay vì để trống khó debug,
/// và không bao giờ crash.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    AdService.instance.loadBanner().then((ad) {
      if (mounted) setState(() => _ad = ad);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) {
      // Giữ chỗ cho bản dev: ở bản release có thể thay bằng SizedBox.shrink().
      return const SizedBox(
        height: 50,
        child: Center(child: Text('Quảng cáo banner (đang tải / không có quảng cáo)')),
      );
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
