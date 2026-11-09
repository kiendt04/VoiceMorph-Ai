import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_core/voice_core.dart';

import '../../core/strings.dart';
import '../../services/entitlement/entitlement_service.dart';
import '../common/providers.dart';
import '../flow/flow_args.dart';

/// Màn chọn hiệu ứng: lưới 12 preset + tìm kiếm.
/// - Preset thường -> sang FineTune.
/// - Preset PRO chưa mở -> sang Paywall (Giai đoạn 3: chưa có mua thật,
///   mở tạm bằng rewarded 24 giờ hoặc đợi mua PRO sau).
/// - Preset PRO đã mở (mua PRO / mở tạm còn hạn) -> sang FineTune.
/// - Chưa có nguồn (bấm preset ở Home khi chưa ghi) -> nhắc ghi/import trước.
class EffectsScreen extends ConsumerStatefulWidget {
  const EffectsScreen({super.key, this.args});

  final EffectsArgs? args;

  @override
  ConsumerState<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends ConsumerState<EffectsScreen> {
  var _query = '';

  void _pick(EffectPreset preset) {
    final s = AppLocalizations.of(context);
    final source = widget.args?.source;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('effectsNeedSource'))),
      );
      return;
    }
    // PRO chưa mở (kể cả mở tạm đã hết hạn) thì sang Paywall; đã mở thì
    // đi thẳng vào FineTune như preset thường.
    if (preset.isPro &&
        !ref.read(entitlementProvider).isPresetUnlocked(preset)) {
      context.push('/paywall', extra: PaywallArgs(preset: preset, source: source));
      return;
    }
    context.push('/editor', extra: EditorArgs(source: source, preset: preset));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final presets = ref.watch(presetListProvider);
    final source = widget.args?.source;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('effectsTitle'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: s.t('effectsSearchHint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (source == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.t('effectsNoSource'))),
                      ElevatedButton(
                        onPressed: () => context.push('/record'),
                        child: Text(s.t('effectsRecordBtn')),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${s.t('effectsSource')}: ${source.name}'),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: presets.when(
              data: (all) {
                final filtered = all.where((p) {
                  if (_query.isEmpty) return true;
                  return p.name('vi').toLowerCase().contains(_query) ||
                      p.name('en').toLowerCase().contains(_query) ||
                      p.id.contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text(s.t('effectsNotFound')));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final preset = filtered[index];
                    final preselected =
                        preset.id == widget.args?.preselectedPresetId;
                    final locked = preset.isPro &&
                        !ref
                            .watch(entitlementProvider)
                            .isPresetUnlocked(preset);
                    return Card(
                      color: preselected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25)
                          : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _pick(preset),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                locked ? Icons.lock : Icons.audiotrack,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name(s.locale.languageCode),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (preset.isPro)
                                const Chip(label: Text('PRO'))
                              else
                                Text(
                                  preset.category,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${s.t('effectsLoadFailed')}: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
