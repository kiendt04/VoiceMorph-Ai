import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/strings.dart';
import '../../services/audio/audio_format.dart';
import '../../services/settings/settings_service.dart';
import '../common/providers.dart';

/// Màn Cài đặt thật (Giai đoạn 3).
///
/// - Giao diện: Hệ thống / Tối / Sáng (đổi ngay, lưu vào SettingsService).
/// - Định dạng xuất mặc định + bitrate (dùng ở màn Result khi mở lên).
/// - Ngôn ngữ Việt / English (đổi ngay toàn app qua AppLocalizations).
/// - Sử dụng có trách nhiệm, Chính sách riêng tư (nội dung tĩnh).
/// - Xóa dữ liệu: xóa thư viện + file tạm, KHÔNG xóa cài đặt hay PRO.
/// - Về ứng dụng: tên + phiên bản lấy từ pubspec (1.0.0+1).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settingsClearTitle')),
        content: Text(s.t('settingsClearBody')),
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
    if (confirmed != true || !context.mounted) return;
    await ref.read(libraryProvider.notifier).deleteAllLocal();
    // File tạm của luồng đổi giọng (renders, recordings, preview) nằm ở
    // thư mục tạm của hệ thống; xóa các thư mục con app đã tạo.
    try {
      final temp = await getTemporaryDirectory();
      for (final name in ['renders', 'recordings']) {
        final dir = Directory('${temp.path}/$name');
        if (dir.existsSync()) await dir.delete(recursive: true);
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('settingsClearDone'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final format = ExportFormat.fromExtension(settings.defaultExportFormat);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.t('settingsTheme'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            title: Text(s.t('settingsThemeSystem')),
            value: 'system',
            groupValue: settings.themeMode,
            onChanged: (v) => v == null ? null : notifier.setThemeMode(v),
          ),
          RadioListTile<String>(
            title: Text(s.t('settingsThemeDark')),
            value: 'dark',
            groupValue: settings.themeMode,
            onChanged: (v) => v == null ? null : notifier.setThemeMode(v),
          ),
          RadioListTile<String>(
            title: Text(s.t('settingsThemeLight')),
            value: 'light',
            groupValue: settings.themeMode,
            onChanged: (v) => v == null ? null : notifier.setThemeMode(v),
          ),
          const Divider(),
          Text(
            s.t('settingsExport'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<ExportFormat>(
                  value: format,
                  isExpanded: true,
                  items: [
                    for (final f in ExportFormat.values)
                      DropdownMenuItem(
                        value: f,
                        child: Text(f.labelFor(settings.language)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.setDefaultExportFormat(v.extension);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: settings.defaultExportBitrate,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 128, child: Text('128 kbps')),
                    DropdownMenuItem(value: 192, child: Text('192 kbps')),
                    DropdownMenuItem(value: 320, child: Text('320 kbps')),
                  ],
                  onChanged: format == ExportFormat.wav
                      ? null
                      : (v) {
                          if (v != null) {
                            notifier.setDefaultExportBitrate(v);
                          }
                        },
                ),
              ),
            ],
          ),
          const Divider(),
          Text(
            s.t('settingsLanguage'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            title: Text(s.t('settingsVietnamese')),
            value: 'vi',
            groupValue: settings.language,
            onChanged: (v) => v == null ? null : notifier.setLanguage(v),
          ),
          RadioListTile<String>(
            title: Text(s.t('settingsEnglish')),
            value: 'en',
            groupValue: settings.language,
            onChanged: (v) => v == null ? null : notifier.setLanguage(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: Text(s.t('settingsResponsibleUse')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/responsible-use'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(s.t('settingsPrivacy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(s.t('settingsPrivacy')),
                content: SingleChildScrollView(
                  child: Text(s.t('settingsPrivacyBody')),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.t('gotIt')),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(s.t('settingsClearData')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _clearData(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(s.t('settingsAbout')),
            subtitle: Text(
              '${s.t('settingsAboutBody')}\n${s.t('settingsVersion')}: 1.0.0+1',
            ),
          ),
        ],
      ),
    );
  }
}
