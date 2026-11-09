import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_service.dart';
import 'ad_service.dart';

/// Cổng interstitial sau render (theo báo cáo vận hành ads Giai đoạn 3).
///
/// Chỉ hiện khi ĐỦ cả 4 điều kiện:
/// - đã render thành công từ lần thứ 3 trở đi (đếm tích lũy),
/// - tối đa 1 lần trong một phiên chạy app,
/// - lần trước cách đây ít nhất 3 phút,
/// - tối đa 3 lần trong một ngày.
/// Quảng cáo lỗi/không hiện được thì không chặn luồng: hàm trả về false
/// và màn hình vẫn sang Result bình thường.
class InterstitialGate {
  static bool _shownThisSession = false;

  static Future<bool> maybeShowAfterRender(WidgetRef ref) async {
    final settings = ref.read(settingsProvider.notifier);
    await settings.incrementRenderSuccessCount();
    final state = ref.read(settingsProvider);
    if (state.renderSuccessCount < 3) return false;
    if (_shownThisSession) return false;
    final now = DateTime.now();
    if (state.interstitialLastShownMs > 0 &&
        now.millisecondsSinceEpoch - state.interstitialLastShownMs <
            const Duration(minutes: 3).inMilliseconds) {
      return false;
    }
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayCount = state.interstitialShownDate == today
        ? state.interstitialShownTodayCount
        : 0;
    if (todayCount >= 3) return false;
    final shown = await AdService.instance.showInterstitial();
    if (shown) {
      _shownThisSession = true;
      await settings.recordInterstitialShown(now);
    }
    return shown;
  }
}
