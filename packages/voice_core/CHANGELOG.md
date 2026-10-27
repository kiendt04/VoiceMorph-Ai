# Changelog — voice_core

## 0.2.0 (chưa phát hành)
- `VoiceChanger.renderFile` giờ tự tạo thư mục đích và ghi đè output cũ
  (trước đây `rename` có thể lỗi trên nền tảng không cho ghi đè).
- `VoiceChanger.render` kiểm tra `sampleRate` phải dương, lỗi rõ ràng thay vì
  lỗi chia cho 0 sâu trong filter.
- Thêm `audio_utils.dart`: `computePeaks` (vẽ waveform), `peakLevel`,
  `applyFade` (chống click ở đầu/cuối clip), `trimSilence` (cắt khoảng lặng
  đầu/cuối bản ghi) kèm test riêng.
