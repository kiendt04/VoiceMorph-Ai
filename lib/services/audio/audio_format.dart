/// Định dạng âm thanh của Giai đoạn 2: import MP3/M4A, xuất WAV/MP3/M4A.
///
/// Luồng trong app vẫn chạy trên WAV (voice_core chỉ đọc/ghi WAV):
/// file import không phải WAV sẽ được giải mã về WAV tạm trước khi vào
/// FineTune/Processing; file đã render (WAV) sẽ được mã hóa lại khi người
/// dùng chọn xuất MP3/M4A. Vì vậy enum này chỉ mô tả định dạng ở rìa
/// (import/export), không chạm vào lõi DSP.
enum ExportFormat {
  wav('wav', 'WAV (gốc)'),
  mp3('mp3', 'MP3'),
  m4a('m4a', 'M4A (AAC)');

  const ExportFormat(this.extension, this.label);

  final String extension;
  final String label;

  static ExportFormat fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
        return ExportFormat.mp3;
      case 'm4a':
      case 'aac':
        return ExportFormat.m4a;
      case 'wav':
      default:
        return ExportFormat.wav;
    }
  }
}

/// Các đuôi import được chấp nhận ở Home (Giai đoạn 2).
const supportedImportExtensions = {'wav', 'mp3', 'm4a'};

/// Lỗi ở tầng định dạng: file hỏng, codec không hỗ trợ, hết dung lượng,
/// hoặc FFmpeg chạy thất bại. UI hiện thẳng [message] cho người dùng và
/// cho thử lại — không để exception kỹ thuật thô lọt ra màn hình.
class AudioFormatException implements Exception {
  const AudioFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

String fileExtension(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot < 0) return '';
  return name.substring(dot + 1).toLowerCase();
}
