import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../services/settings/settings_service.dart';

/// Màn Sử dụng có trách nhiệm (Giai đoạn 3).
///
/// Hiện một lần ở lần đầu mở Home sau onboarding, và trước lần chia sẻ
/// đầu tiên từ màn Result. Nội dung ngắn, không dọa nạt: app để vui,
/// không giả giọng người thật để lừa, không quấy rối, không ghi âm lén.
class ResponsibleUseScreen extends StatelessWidget {
  const ResponsibleUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('responsibleTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  s.t('responsibleBody'),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.t('gotIt')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hiện dialog Sử dụng có trách nhiệm và đánh dấu đã chấp nhận khi người
/// dùng bấm "Đã hiểu". Trả về true khi người dùng đã bấm nút đó.
Future<bool> showResponsibleUseDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final s = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(s.t('responsibleTitle')),
      content: Text(s.t('responsibleBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.t('gotIt')),
        ),
      ],
    ),
  );
  if (accepted == true) {
    await ref
        .read(settingsProvider.notifier)
        .setResponsibleUseAccepted(true);
    return true;
  }
  return false;
}
