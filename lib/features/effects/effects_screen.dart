import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_core/voice_core.dart';

import '../common/providers.dart';
import '../flow/flow_args.dart';

/// Màn chọn hiệu ứng: lưới 12 preset + tìm kiếm.
/// - Preset thường -> sang FineTune.
/// - Preset PRO -> sang Paywall (chưa gắn thanh toán thật ở Giai đoạn 1).
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
    final source = widget.args?.source;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghi âm hoặc import file trước rồi mới chọn hiệu ứng nhé.'),
        ),
      );
      return;
    }
    if (preset.isPro) {
      context.push('/paywall');
      return;
    }
    context.push('/editor', extra: EditorArgs(source: source, preset: preset));
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetListProvider);
    final source = widget.args?.source;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn hiệu ứng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm hiệu ứng...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
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
                      const Expanded(
                        child: Text('Chưa có bản ghi nào. Ghi âm hoặc import file trước nhé.'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/record'),
                        child: const Text('Ghi âm'),
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
                child: Text('Nguồn: ${source.name}'),
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
                  return const Center(child: Text('Không tìm thấy hiệu ứng nào.'));
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
                                preset.isPro ? Icons.lock : Icons.audiotrack,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name('vi'),
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
                child: Text('Không tải được preset: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
