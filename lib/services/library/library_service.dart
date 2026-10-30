import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Một bản đã lưu trong thư viện: file đã đổi giọng (+ file gốc để đối
/// chiếu nếu cần), lưu trong thư mục documents của app.
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.name,
    required this.fileName,
    this.originalFileName,
    required this.createdAt,
    this.favorite = false,
  });

  final String id;
  final String name;
  final String fileName;
  final String? originalFileName;
  final DateTime createdAt;
  final bool favorite;

  LibraryEntry copyWith({String? name, bool? favorite}) => LibraryEntry(
        id: id,
        name: name ?? this.name,
        fileName: fileName,
        originalFileName: originalFileName,
        createdAt: createdAt,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
        'originalFileName': originalFileName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'favorite': favorite,
      };

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        fileName: json['fileName'] as String,
        originalFileName: json['originalFileName'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        favorite: json['favorite'] as bool? ?? false,
      );
}

/// Lưu trữ thư viện: file WAV trong `documents/library/`, index JSON đi kèm.
/// Không dùng database để Giai đoạn 1 giữ đơn giản; số lượng bản lưu của
/// người dùng phổ thông không đủ lớn để JSON thành vấn đề.
class LibraryService {
  Future<Directory> get _libraryDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/library');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> get _indexFile async {
    final dir = await _libraryDir;
    return File('${dir.path}/index.json');
  }

  /// Đọc index, bỏ qua các entry mà file đã bị xóa ngoài app.
  Future<List<LibraryEntry>> loadEntries() async {
    try {
      final dir = await _libraryDir;
      final index = await _indexFile;
      if (!index.existsSync()) return [];
      final raw = jsonDecode(await index.readAsString()) as List;
      final entries = <LibraryEntry>[];
      for (final item in raw) {
        final entry = LibraryEntry.fromJson(item as Map<String, dynamic>);
        if (File('${dir.path}/${entry.fileName}').existsSync()) {
          entries.add(entry);
        }
      }
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIndex(List<LibraryEntry> entries) async {
    final index = await _indexFile;
    await index.writeAsString(
      jsonEncode([for (final e in entries) e.toJson()]),
      flush: true,
    );
  }

  /// Lưu file đã render (kèm file gốc nếu có) vào thư viện, trả về entry mới.
  /// Giai đoạn 2: giữ đúng đuôi của file được lưu (WAV/MP3/M4A) thay vì
  /// ép về .wav như Giai đoạn 1 — Library phát lại bằng just_audio nên
  /// đọc được cả ba định dạng.
  Future<LibraryEntry> addRendered({
    required String renderedPath,
    String? originalPath,
    required String name,
  }) async {
    final dir = await _libraryDir;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'vm_$stamp.${_extension(renderedPath)}';
    await File(renderedPath).copy('${dir.path}/$fileName');
    String? originalFileName;
    if (originalPath != null && File(originalPath).existsSync()) {
      originalFileName = 'vm_${stamp}_orig.${_extension(originalPath)}';
      await File(originalPath).copy('${dir.path}/$originalFileName');
    }
    final entry = LibraryEntry(
      id: stamp.toString(),
      name: name,
      fileName: fileName,
      originalFileName: originalFileName,
      createdAt: DateTime.now(),
    );
    final entries = await loadEntries();
    entries.insert(0, entry);
    await _saveIndex(entries);
    return entry;
  }

  Future<void> rename(String id, String name) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    entries[index] = entries[index].copyWith(name: name);
    await _saveIndex(entries);
  }

  Future<void> toggleFavorite(String id) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    entries[index] = entries[index].copyWith(favorite: !entries[index].favorite);
    await _saveIndex(entries);
  }

  Future<void> delete(String id) async {
    final dir = await _libraryDir;
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final entry = entries[index];
    final rendered = File('${dir.path}/${entry.fileName}');
    if (rendered.existsSync()) await rendered.delete();
    if (entry.originalFileName != null) {
      final original = File('${dir.path}/${entry.originalFileName}');
      if (original.existsSync()) await original.delete();
    }
    entries.removeAt(index);
    await _saveIndex(entries);
  }

  String _extension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return 'wav';
    final ext = name.substring(dot + 1).toLowerCase();
    return ext.isEmpty ? 'wav' : ext;
  }

  /// Đường dẫn tuyệt đối của file đã render của một entry.
  Future<String> filePath(LibraryEntry entry) async {
    final dir = await _libraryDir;
    return '${dir.path}/${entry.fileName}';
  }
}
