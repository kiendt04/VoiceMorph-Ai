import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_format.dart';

/// Cầu nối duy nhất giữa app và FFmpeg (bản audio, LGPL, không chứa
/// codec GPL). Mọi lệnh FFmpeg của app đều qua đây để khi cần đổi
/// package FFmpeg chỉ sửa một file này.
///
/// - Import: MP3/M4A -> WAV mono 44.1kHz tạm (khớp với bản ghi mic).
/// - Xuất: WAV đã render -> MP3 (libmp3lame) hoặc M4A (AAC native).
/// - WAV đi thẳng, không qua FFmpeg, để tránh mã hóa lại không cần thiết.
class AudioTranscoder {
  /// Giải mã [inputPath] về một file WAV tạm. WAV trả về chính đường dẫn
  /// gốc (không copy). File hỏng / codec lạ -> [AudioFormatException]
  /// với thông báo người dùng hiểu được, kèm gợi ý thử lại.
  Future<String> decodeToWav(String inputPath) async {
    final input = File(inputPath);
    if (!input.existsSync()) {
      throw const AudioFormatException(
        'Không tìm thấy file vừa chọn. Chọn lại file khác nhé.',
      );
    }
    if (input.lengthSync() == 0) {
      throw const AudioFormatException(
        'File vừa chọn rỗng (0 byte), không giải mã được.',
      );
    }
    final ext = fileExtension(inputPath);
    if (ext == 'wav') return inputPath;
    if (!supportedImportExtensions.contains(ext)) {
      throw AudioFormatException(
        'Định dạng .$ext chưa hỗ trợ. App nhận WAV, MP3 và M4A.',
      );
    }
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/decoded');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final output =
        '${dir.path}/decoded_${DateTime.now().millisecondsSinceEpoch}.wav';
    // -vn: bỏ track video (file M4A/MP3 đôi khi kèm ảnh bìa).
    // -ac 1 -ar 44100: về mono 44.1kHz, khớp bản ghi mic và voice_core.
    await _run(
      '-y -i ${_quote(inputPath)} -vn -ac 1 -ar 44100 -f wav ${_quote(output)}',
      output,
      'Không giải mã được file này. File có thể đã hỏng hoặc dùng codec '
      'không hỗ trợ — thử file khác hoặc xuất lại file từ app gốc nhé.',
      minSize: 45, // WAV hợp lệ phải dài hơn header 44 byte.
    );
    return output;
  }

  /// Mã hóa file WAV đã render sang [format]. WAV trả về chính đường dẫn
  /// gốc. Bitrate chỉ áp dụng cho MP3/M4A (mặc định 192 kbps).
  Future<String> encodeFromWav(
    String wavPath,
    ExportFormat format, {
    int bitrateKbps = 192,
  }) async {
    if (format == ExportFormat.wav) return wavPath;
    final input = File(wavPath);
    if (!input.existsSync() || input.lengthSync() == 0) {
      throw const AudioFormatException(
        'Chưa có file đã render để xuất. Xử lý lại một bản rồi xuất nhé.',
      );
    }
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/exports');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final output =
        '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.${format.extension}';
    final codec = format == ExportFormat.mp3 ? 'libmp3lame' : 'aac';
    await _run(
      '-y -i ${_quote(wavPath)} -vn -c:a $codec -b:a ${bitrateKbps}k ${_quote(output)}',
      output,
      'Không xuất được file ${format.extension.toUpperCase()}. Kiểm tra '
      'dung lượng trống còn lại rồi thử lại nhé.',
    );
    return output;
  }

  Future<void> _run(
    String command,
    String outputPath,
    String errorMessage, {
    int minSize = 1,
  }) async {
    final output = File(outputPath);
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode) ||
          !output.existsSync() ||
          output.lengthSync() < minSize) {
        if (output.existsSync()) {
          try {
            output.deleteSync();
          } catch (_) {}
        }
        throw AudioFormatException(errorMessage);
      }
    } on AudioFormatException {
      rethrow;
    } catch (_) {
      // FFmpeg lỗi hệ thống (vd: hết dung lượng, bị kill): không để
      // exception kỹ thuật lọt ra UI, quy về một thông báo thử lại được.
      if (output.existsSync()) {
        try {
          output.deleteSync();
        } catch (_) {}
      }
      throw AudioFormatException(errorMessage);
    }
  }

  /// Đường dẫn có khoảng trắng/ký tự đặc biệt phải đặt trong dấu ngoặc
  /// kép thì parser của FFmpegKit mới tách đúng thành một đối số.
  String _quote(String path) => '"$path"';
}
