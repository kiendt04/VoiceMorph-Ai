import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../services/ads/ad_service.dart';
import '../../services/entitlement/entitlement_service.dart';
import '../flow/flow_args.dart';

/// Màn Paywall (Giai đoạn 3 — KHÔNG có giao dịch thật).
///
/// Sếp tạm bỏ qua phần thanh toán (sẽ tự tìm hiểu sau), nên màn này chỉ:
/// - liệt kê quyền lợi PRO,
/// - nút "Mua PRO" ở trạng thái tắt kèm ghi chú "sắp có",
/// - nút "Xem quảng cáo để mở hiệu ứng này 24 giờ" (chỉ khi mở từ một
///   preset PRO): xem xong rewarded thì mở tạm preset đó và sang FineTune.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.args});

  final PaywallArgs? args;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  var _busy = false;

  Future<void> _unlockWithRewarded() async {
    final preset = widget.args?.preset;
    final source = widget.args?.source;
    if (preset == null || source == null || _busy) return;
    setState(() => _busy = true);
    final s = AppLocalizations.of(context);
    final ok = await AdService.instance.showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('paywallRewardedFailed'))),
      );
      return;
    }
    await ref.read(entitlementProvider).grantRewardedUnlock(preset.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('paywallRewardedDone'))),
    );
    // Thay Paywall bằng Editor: Back từ Editor về thẳng màn Effects,
    // không quay lại Paywall nữa.
    context.pushReplacement(
      '/editor',
      extra: EditorArgs(source: source, preset: preset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final preset = widget.args?.preset;
    final expiry = preset == null
        ? null
        : ref.watch(entitlementProvider).rewardedUnlockExpiry(preset);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('paywallTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('paywallSubtitle'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final key in [
              'paywallBenefit1',
              'paywallBenefit2',
              'paywallBenefit3',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.t(key))),
                  ],
                ),
              ),
            if (expiry != null) ...[
              const SizedBox(height: 8),
              Text(
                s.t('paywallUnlockedFor', {
                  'd':
                      '${expiry.day}/${expiry.month}/${expiry.year} ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}',
                }),
                style: const TextStyle(color: Colors.green),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              // Nút mua đang tắt: chưa có store. Khi gắn store thật, nối
              // nút này vào RevenueCat/in_app_purchase rồi mở khóa qua
              // EntitlementService.setPurchased.
              child: ElevatedButton(
                onPressed: null,
                child: Text(s.t('paywallBuy')),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                s.t('paywallBuyNote'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            if (preset != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _unlockWithRewarded,
                  icon: const Icon(Icons.play_circle),
                  label: Text(s.t('paywallRewarded')),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(s.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
