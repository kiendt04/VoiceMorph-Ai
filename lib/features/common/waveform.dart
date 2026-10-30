import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Sóng âm vẽ từ PCM thật ([peaks] từ `computePeaks` trong voice_core).
/// Dùng chung cho FineTune (nguồn) và Result (bản đã đổi) để hai màn
/// không tự vẽ mỗi nơi một kiểu.
class WaveformBars extends StatelessWidget {
  const WaveformBars({super.key, required this.peaks, this.height = 64});

  final Float32List peaks;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (peaks.isEmpty) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final peak in peaks)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 4 + peak.clamp(0.0, 1.0) * (height - 8),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
