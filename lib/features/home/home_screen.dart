import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../services/ads/ad_service.dart';
import '../../services/presets/preset_service.dart';
import '../common/providers.dart';
import '../flow/flow_args.dart';

/// Màn Home thật (Giai đoạn 1): nút Ghi âm ngay, Import file WAV, 5 preset
/// nổi bật, bản ghi gần đây từ Library, banner quảng cáo test ở cuối.
/// Bấm preset khi chưa có nguồn -> sang màn Effects, màn đó sẽ nhắc ghi/import.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _import(BuildContext context) async {
    // Giai đoạn 1 chỉ nhận WAV; MP3/M4A để Giai đoạn 2 (cần FFmpeg).
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final name = path.split('/').last;
    if (context.mounted) {
      context.push(
        '/effects',
        extra: EffectsArgs(source: SourceArgs(path: path, name: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetListProvider);
    final library = ref.watch(libraryProvider);
    final recent = library.take(3).toList();
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
                    onPressed: () => _import(context),
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Import file'),
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
          SizedBox(
            height: 120,
            child: presets.when(
              data: (all) {
                final featured = PresetService.featured(all);
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    final preset = featured[index];
                    return SizedBox(
                      width: 140,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.push(
                            '/effects',
                            extra: EffectsArgs(
                              preselectedPresetId: preset.id,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  preset.isPro
                                      ? Icons.lock
                                      : Icons.audiotrack,
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
                                  const Chip(label: Text('PRO')),
                              ],
                            ),
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
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Chưa có bản nào. Ghi âm và lưu một bản để thấy ở đây.',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recent.length,
                    itemBuilder: (context, index) {
                      final entry = recent[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.audiotrack),
                          title: Text(entry.name),
                          trailing: entry.favorite
                              ? const Icon(Icons.star)
                              : null,
                          onTap: () => context.go('/library'),
                        ),
                      );
                    },
                  ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
