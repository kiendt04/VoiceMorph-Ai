import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_core/voice_core.dart';

import '../../services/library/library_service.dart';
import '../../services/presets/preset_service.dart';

/// Provider dùng chung cho toàn app (đặt ở đây để tránh mỗi màn tự định
/// nghĩa một FutureProvider preset riêng rồi tải JSON nhiều lần).

final presetListProvider = FutureProvider<List<EffectPreset>>(
  (ref) => PresetService.loadPresets(),
);

/// Danh sách thư viện, tự tải lại sau mỗi thay đổi. Lỗi đọc (kể cả thiếu
/// plugin trong test) đều coi như thư viện rỗng, không crash app.
class LibraryNotifier extends StateNotifier<List<LibraryEntry>> {
  LibraryNotifier() : super([]) {
    _reload();
  }

  final _service = LibraryService();

  Future<void> _reload() async {
    try {
      state = await _service.loadEntries();
    } catch (_) {
      state = [];
    }
  }

  Future<void> addRendered({
    required String renderedPath,
    String? originalPath,
    required String name,
  }) async {
    await _service.addRendered(
      renderedPath: renderedPath,
      originalPath: originalPath,
      name: name,
    );
    await _reload();
  }

  Future<void> rename(String id, String name) async {
    await _service.rename(id, name);
    await _reload();
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await _reload();
  }

  Future<String> filePath(LibraryEntry entry) => _service.filePath(entry);
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, List<LibraryEntry>>(
  (ref) => LibraryNotifier(),
);
