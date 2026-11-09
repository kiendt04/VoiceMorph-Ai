import 'package:flutter/material.dart';

import '../../core/strings.dart';

/// Màn Giọng AI — sắp ra mắt (Giai đoạn 3).
///
/// Chỉ là màn thông báo: giọng AI là module riêng ở bản sau, chưa có
/// backend nào. App hiện tại chỉ đổi giọng bằng hiệu ứng DSP trên máy.
class AiVoicesScreen extends StatelessWidget {
  const AiVoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('aiTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64),
            const SizedBox(height: 24),
            Text(
              s.t('aiTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              s.t('aiBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
