import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../services/ads/ad_service.dart';
import '../../services/audio/ffmpeg_service.dart';
import '../../services/presets/preset_service.dart';
import '../common/providers.dart';
import '../flow/flow_args.dart';

/// Màn Home thật (Giai đoạn 1 + 2): nút Ghi âm ngay, Import WAV/MP3/M4A,
/// 5 preset nổi bật, bản ghi gần đây từ Library, banner quảng cáo test.
/// Bấm preset khi chưa có nguồn -> sang màn Effects, màn đó sẽ nhắc ghi/import.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final name = path.split('/').last;
    // MP3/M4A cần giải mã về WAV tạm trước khi vào luồng (voice_core
    // chỉ đọc WAV). Hiện dialog chờ vì bước này có thể mất vài giây
    // với file dài; WAV đi thẳng nên dialog chỉ chớp qua.
    if (context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    String decodedPath;
    try {
      decodedPath = await AudioTranscoder().decodeToWav(path);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không import được: $e'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _import(context),
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      Navigator.of(context).pop();
      // Giữ tên file gốc để hiển thị; path bên trong là WAV đã giải mã.
      context.push(
        '/effects',
        extra: EffectsArgs(source: SourceArgs(path: decodedPath, name: name)),
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
            height: 140,
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
                                // Flexible + 2 dòng: tên dài như "Người ngoài
                                // hành tinh" co lại thay vì làm tràn thẻ.
                                Flexible(
                                  child: Text(
                                    preset.name('vi'),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Nhãn nhỏ thay cho Chip: Chip cao ~48px làm
                                // tràn thẻ preset.
                                if (preset.isPro)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
