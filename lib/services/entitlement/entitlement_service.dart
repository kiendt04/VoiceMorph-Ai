import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_core/voice_core.dart';

import '../settings/settings_service.dart';

/// Nguồn sự thật duy nhất cho quyền lợi (Giai đoạn 3).
///
/// - Mua PRO: CHƯA CÓ. Sếp tạm bỏ qua phần giao dịch/thanh toán, sẽ tự
///   tìm hiểu sau, nên [isPurchased] luôn là false. Khi gắn store thật
///   (RevenueCat hoặc in_app_purchase), chỉ cần nối [setPurchased] vào
///   callback mua/khôi phục của store — mọi màn hình khác không phải sửa.
/// - Mở tạm bằng rewarded: xem xong quảng cáo rewarded thì mở một preset
///   PRO trong 24 giờ (ghi vào SettingsService, hết hạn tự khóa lại).
/// - Quảng cáo: chỉ khi mua PRO mới tắt. Mở tạm bằng rewarded KHÔNG tắt
///   quảng cáo (chỉ mở hiệu ứng).
class EntitlementService {
  EntitlementService(this._ref);

  final Ref _ref;

  /// Chưa có giao dịch thật nên luôn false (xem ghi chú ở đầu file).
  bool get isPurchased => false;

  /// Chỗ nối cho store sau này: khi mua/khôi phục thành công, store gọi
  /// hàm này. Hiện tại không làm gì vì chưa có store.
  void setPurchased(bool value) {
    // Dành cho Giai đoạn 3 sau này (gắn store). Không gọi ở đâu lúc này.
  }

  bool isPresetUnlocked(EffectPreset preset) {
    if (!preset.isPro) return true;
    if (isPurchased) return true;
    final expiry = _ref.read(settingsProvider).rewardedUnlocks[preset.id];
    return expiry != null &&
        expiry > DateTime.now().millisecondsSinceEpoch;
  }

  /// Hạn mở tạm còn lại của một preset (null nếu không mở hoặc đã hết hạn).
  DateTime? rewardedUnlockExpiry(EffectPreset preset) {
    final expiry = _ref.read(settingsProvider).rewardedUnlocks[preset.id];
    if (expiry == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(expiry);
    return date.isAfter(DateTime.now()) ? date : null;
  }

  /// Mở preset PRO trong 24 giờ sau khi xem xong quảng cáo rewarded.
  Future<void> grantRewardedUnlock(String presetId) async {
    final expiry = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await _ref.read(settingsProvider.notifier).grantRewardedUnlock(
          presetId,
          expiry,
        );
  }

  /// Quảng cáo chỉ tắt khi đã mua PRO.
  bool get adsEnabled => !isPurchased;
}

final entitlementProvider = Provider<EntitlementService>((ref) {
  // watch để màn nào watch entitlementProvider (lưới Effects, Paywall)
  // cũng vẽ lại khi settings đổi, ví dụ vừa mở tạm preset bằng rewarded.
  ref.watch(settingsProvider);
  return EntitlementService(ref);
});
