import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_core/voice_core.dart';

import '../../services/ads/ad_service.dart';
import '../../services/presets/preset_service.dart';

final _presetListProvider = FutureProvider<List<EffectPreset>>(
  (ref) => PresetService.loadPresets(),
);

/// Màn hình Home tạm của Giai đoạn 0: hiển thị đúng 5 preset nổi bật từ
/// JSON (kèm cờ PRO), nút đi tới các route chính, và banner quảng cáo test
/// ở cuối để kiểm chứng AdService. Màn hình thật đầy đủ dựng ở Giai đoạn 1.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(_presetListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceMorph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Cài đặt',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/record'),
                    icon: const Icon(Icons.mic),
                    label: const Text('Ghi âm'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.folder),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hiệu ứng nổi bật',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: presets.when(
              data: (all) {
                final featured = PresetService.featured(all);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    final preset = featured[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.audiotrack),
                        title: Text(preset.name('vi')),
                        subtitle: Text(preset.category),
                        trailing: preset.isPro
                            ? const Chip(label: Text('PRO'))
                            : const Icon(Icons.play_arrow),
                        onTap: () => context.go('/effects'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Không tải được preset: $error'),
              ),
            ),
          ),
          // Nút kiểm chứng quảng cáo test (chỉ ở màn hình tạm Giai đoạn 0).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => AdService.instance.showInterstitial(),
                    child: const Text('Test interstitial'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final earned = await AdService.instance.showRewarded();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              earned ? 'Đã nhận thưởng (test)' : 'Chưa nhận thưởng',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Test rewarded'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
