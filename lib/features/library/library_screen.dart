import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/strings.dart';
import '../../services/ads/ad_service.dart';
import '../../services/entitlement/entitlement_service.dart';
import '../../services/library/library_service.dart';
import '../common/providers.dart';

/// Màn Library: danh sách bản đã lưu, tìm kiếm, đổi tên, xóa, yêu thích.
/// Bấm vào một bản để nghe thử bản đã đổi đó. Chưa có bản nào -> màn Empty.
/// Banner quảng cáo ở cuối màn này (Giai đoạn 3, theo báo cáo ads), chỉ
/// hiện khi chưa mua PRO.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _player = AudioPlayer();
  var _query = '';
  String? _playingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(LibraryEntry entry) async {
    if (_playingId == entry.id) {
      await _player.pause();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      final path =
          await ref.read(libraryProvider.notifier).filePath(entry);
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
      if (mounted) setState(() => _playingId = entry.id);
      _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).then((_) {
        if (mounted && _playingId == entry.id) {
          setState(() => _playingId = null);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không phát được: $e')),
        );
      }
    }
  }

  Future<void> _rename(LibraryEntry entry) async {
    final s = AppLocalizations.of(context);
    final controller = TextEditingController(text: entry.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('libraryRenameTitle')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: s.t('libraryRenameHint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != entry.name) {
      await ref.read(libraryProvider.notifier).rename(entry.id, name);
    }
  }

  Future<void> _delete(LibraryEntry entry) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('libraryDeleteTitle')),
        content: Text(s.t('libraryDeleteBody', {'n': entry.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(libraryProvider.notifier).delete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final entries = ref.watch(libraryProvider);
    final adsEnabled = ref.watch(entitlementProvider).adsEnabled;
    final filtered = entries.where((e) {
      if (_query.isEmpty) return true;
      return e.name.toLowerCase().contains(_query);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('libraryTitle'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: s.t('librarySearchHint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 64),
                        const SizedBox(height: 16),
                        Text(s.t('libraryEmptyTitle')),
                        Text(s.t('libraryEmptyBody')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/record'),
                          child: Text(s.t('libraryRecordNow')),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(child: Text(s.t('libraryNotFound')))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final playing = _playingId == entry.id;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                playing
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              title: Text(entry.name),
                              subtitle: Text(
                                '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}'
                                '${entry.favorite ? ' • ${s.t('libraryFavorite')}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      entry.favorite
                                          ? Icons.star
                                          : Icons.star_border,
                                    ),
                                    onPressed: () => ref
                                        .read(libraryProvider.notifier)
                                        .toggleFavorite(entry.id),
                                    tooltip: s.t('libraryFavorite'),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'rename') {
                                        _rename(entry);
                                      } else if (value == 'delete') {
                                        _delete(entry);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text(s.t('libraryRenameTitle')),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(s.t('delete')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _togglePlay(entry),
                            ),
                          );
                        },
                      ),
          ),
          // Banner ở cuối màn Library (Giai đoạn 3); mua PRO thì ẩn hẳn.
          if (adsEnabled) const AdBannerWidget(),
        ],
      ),
    );
  }
}
