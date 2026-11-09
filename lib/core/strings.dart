import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Chuỗi hiển thị duy nhất của app (Giai đoạn 3).
///
/// Mọi chuỗi người dùng nhìn thấy (tiêu đề, nút, gợi ý, snackbar, dialog,
/// màn trống) đều lấy từ đây theo ngôn ngữ đang chọn trong Settings
/// ('vi' mặc định, 'en'). Tên preset lấy từ JSON nên giữ nguyên.
/// Thông báo lỗi kèm exception (dạng `...: $e`) giữ nguyên dạng đó và
/// không đưa vào đây, vì phần `$e` là lỗi kỹ thuật từ hệ thống.
class AppStrings {
  static const _values = <String, Map<String, String>>{
    // Chung
    'appTitle': {'vi': 'VoiceMorph', 'en': 'VoiceMorph'},
    'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
    'save': {'vi': 'Lưu', 'en': 'Save'},
    'delete': {'vi': 'Xóa', 'en': 'Delete'},
    'keep': {'vi': 'Giữ lại', 'en': 'Keep'},
    'retry': {'vi': 'Thử lại', 'en': 'Retry'},
    'back': {'vi': 'Quay lại', 'en': 'Back'},
    'gotIt': {'vi': 'Đã hiểu', 'en': 'Got it'},
    'later': {'vi': 'Để sau', 'en': 'Later'},
    'close': {'vi': 'Đóng', 'en': 'Close'},
    'cannotPlay': {'vi': 'Không phát được', 'en': "Couldn't play"},
    'cannotSave': {'vi': 'Không lưu được', 'en': "Couldn't save"},
    'cannotShare': {'vi': 'Không chia sẻ được', 'en': "Couldn't share"},

    // Home
    'homeSettings': {'vi': 'Cài đặt', 'en': 'Settings'},
    'homeRecord': {'vi': 'Ghi âm', 'en': 'Record'},
    'homeImport': {'vi': 'Import file', 'en': 'Import file'},
    'homeLibrary': {'vi': 'Thư viện', 'en': 'Library'},
    'homeFeatured': {'vi': 'Hiệu ứng nổi bật', 'en': 'Featured effects'},
    'homeRecent': {'vi': 'Gần đây', 'en': 'Recent'},
    'homeEmpty': {
      'vi': 'Chưa có bản nào. Ghi âm và lưu một bản để thấy ở đây.',
      'en': 'Nothing yet. Record and save a take to see it here.'
    },
    'homeAiVoices': {'vi': 'Giọng AI — sắp ra mắt', 'en': 'AI Voices — coming soon'},
    'homeAiVoicesSub': {
      'vi': 'Đổi danh tính giọng bằng AI, sẽ có ở bản sau.',
      'en': 'Change your voice identity with AI, in a later release.'
    },
    'homeImportFailed': {'vi': 'Không import được', 'en': "Couldn't import"},

    // Effects
    'effectsTitle': {'vi': 'Chọn hiệu ứng', 'en': 'Choose an effect'},
    'effectsSearchHint': {'vi': 'Tìm hiệu ứng...', 'en': 'Search effects...'},
    'effectsNoSource': {
      'vi': 'Chưa có bản ghi nào. Ghi âm hoặc import file trước nhé.',
      'en': 'No recording yet. Record or import a file first.'
    },
    'effectsRecordBtn': {'vi': 'Ghi âm', 'en': 'Record'},
    'effectsSource': {'vi': 'Nguồn', 'en': 'Source'},
    'effectsNotFound': {
      'vi': 'Không tìm thấy hiệu ứng nào.',
      'en': 'No effects found.'
    },
    'effectsNeedSource': {
      'vi': 'Ghi âm hoặc import file trước rồi mới chọn hiệu ứng nhé.',
      'en': 'Record or import a file before choosing an effect.'
    },
    'effectsLoadFailed': {
      'vi': 'Không tải được preset',
      'en': "Couldn't load presets"
    },

    // Record
    'recordTitle': {'vi': 'Ghi âm', 'en': 'Record'},
    'recordNoMic': {
      'vi': 'Chưa có quyền micro nên chưa ghi được.',
      'en': 'Microphone permission is missing, so recording is unavailable.'
    },
    'recordNotAllowed': {
      'vi': 'Thiết bị không cho phép ghi âm lúc này.',
      'en': 'This device does not allow recording right now.'
    },
    'recordFailed': {'vi': 'Không ghi được', 'en': "Couldn't record"},
    'recordStopFailed': {
      'vi': 'Không dừng được bản ghi',
      'en': "Couldn't stop the recording"
    },
    'recordNeedMicTitle': {'vi': 'Cần quyền micro', 'en': 'Microphone needed'},
    'recordNeedMicBody': {
      'vi': 'Quyền micro đã bị từ chối vĩnh viễn. Mở Cài đặt để bật lại nhé.',
      'en': 'Microphone permission was denied permanently. Open Settings to turn it back on.'
    },
    'recordOpenSettings': {'vi': 'Mở Cài đặt', 'en': 'Open Settings'},
    'recordRecording': {
      'vi': 'Đang ghi... bấm Dừng khi nói xong',
      'en': 'Recording... tap Stop when you are done'
    },
    'recordIdle': {
      'vi': 'Bấm nút mic để bắt đầu ghi',
      'en': 'Tap the mic button to start recording'
    },
    'recordStop': {'vi': 'Dừng', 'en': 'Stop'},
    'recordDiscard': {'vi': 'Hủy bản ghi', 'en': 'Discard recording'},
    'recordStart': {'vi': 'Bắt đầu ghi', 'en': 'Start recording'},
    'recordName': {'vi': 'Bản ghi {s} giây', 'en': 'Recording {s} seconds'},

    // Editor (FineTune)
    'editorTitle': {'vi': 'Chỉnh', 'en': 'Tune'},
    'editorSource': {'vi': 'Nguồn', 'en': 'Source'},
    'editorDuration': {'vi': 'Độ dài', 'en': 'Length'},
    'editorSeconds': {'vi': 'giây', 'en': 's'},
    'editorNoControls': {
      'vi': 'Preset này không có thanh trượt — dùng nguyên bản thiết kế của preset.',
      'en': 'This preset has no sliders — it uses the preset design as-is.'
    },
    'editorPreviewBusy': {
      'vi': 'Đang tạo bản nghe thử...',
      'en': 'Making the preview...'
    },
    'editorPreviewStop': {'vi': 'Dừng nghe thử', 'en': 'Stop preview'},
    'editorPreview': {'vi': 'Nghe thử 10 giây', 'en': 'Preview 10 seconds'},
    'editorProcess': {'vi': 'Xử lý toàn file', 'en': 'Process full file'},
    'editorLoadFailed': {
      'vi': 'Không đọc được file nguồn',
      'en': "Couldn't read the source file"
    },
    'editorPreviewFailed': {
      'vi': 'Không nghe thử được',
      'en': "Couldn't play the preview"
    },

    // Processing
    'processingTitle': {'vi': 'Đang xử lý', 'en': 'Processing'},
    'processingFailedTitle': {'vi': 'Xử lý thất bại', 'en': 'Processing failed'},
    'processingFailed': {
      'vi': 'Không xử lý được file',
      'en': "Couldn't process the file"
    },
    'processingCancel': {'vi': 'Hủy', 'en': 'Cancel'},
    'processingPreset': {'vi': 'Preset', 'en': 'Preset'},

    // Result
    'resultTitle': {'vi': 'Kết quả', 'en': 'Result'},
    'resultOriginal': {'vi': 'Bản gốc', 'en': 'Original'},
    'resultChanged': {'vi': 'Đã đổi', 'en': 'Changed'},
    'resultWaveHint': {
      'vi': 'Sóng âm bản đã đổi (từ PCM thật)',
      'en': 'Waveform of the changed take (from real PCM)'
    },
    'resultExportFormat': {'vi': 'Định dạng xuất', 'en': 'Export format'},
    'resultSave': {'vi': 'Lưu vào thư viện', 'en': 'Save to library'},
    'resultSaved': {'vi': 'Đã lưu', 'en': 'Saved'},
    'resultExporting': {'vi': 'Đang xuất...', 'en': 'Exporting...'},
    'resultShare': {'vi': 'Chia sẻ', 'en': 'Share'},
    'resultRingtone': {'vi': 'Nhạc chuông', 'en': 'Ringtone'},
    'resultHome': {'vi': 'Về trang chính', 'en': 'Back to home'},
    'resultSavedFormat': {
      'vi': 'Đã lưu bản {f} vào thư viện.',
      'en': 'Saved the {f} version to the library.'
    },
    'resultExportFailed': {'vi': 'Không xuất được', 'en': "Couldn't export"},
    'resultSource': {'vi': 'Nguồn', 'en': 'Source'},
    'resultRingtoneIos': {
      'vi': 'iOS không cho app đặt nhạc chuông trực tiếp.',
      'en': 'iOS does not let apps set ringtones directly.'
    },
    'resultRingtoneTitle': {
      'vi': 'Đặt làm nhạc chuông',
      'en': 'Set as ringtone'
    },
    'resultRingtoneBody': {
      'vi': 'File đã được lưu vào thư mục của app. Mở Cài đặt > Âm thanh > Nhạc chuông trên điện thoại và chọn file vừa lưu nhé.',
      'en': 'The file was saved into the app folder. Open Settings > Sound > Ringtone on your phone and pick the file you just saved.'
    },
    'resultRingtoneFailed': {
      'vi': 'Không lưu được file nhạc chuông',
      'en': "Couldn't save the ringtone file"
    },

    // Library
    'libraryTitle': {'vi': 'Thư viện', 'en': 'Library'},
    'librarySearchHint': {
      'vi': 'Tìm trong thư viện...',
      'en': 'Search the library...'
    },
    'libraryEmptyTitle': {'vi': 'Thư viện trống', 'en': 'Library is empty'},
    'libraryEmptyBody': {
      'vi': 'Ghi âm và đổi giọng một bản rồi lưu lại nhé.',
      'en': 'Record and change a voice, then save it here.'
    },
    'libraryRecordNow': {'vi': 'Ghi âm ngay', 'en': 'Record now'},
    'libraryNotFound': {
      'vi': 'Không tìm thấy bản nào.',
      'en': 'Nothing found.'
    },
    'libraryFavorite': {'vi': 'Yêu thích', 'en': 'Favorite'},
    'libraryRenameTitle': {'vi': 'Đổi tên', 'en': 'Rename'},
    'libraryRenameHint': {'vi': 'Tên bản ghi', 'en': 'Recording name'},
    'libraryDeleteTitle': {'vi': 'Xóa bản này?', 'en': 'Delete this take?'},
    'libraryDeleteBody': {
      'vi': '“{n}” sẽ bị xóa khỏi thư viện và khỏi máy.',
      'en': '“{n}” will be removed from the library and from the device.'
    },

    // Onboarding
    'onboardingSkip': {'vi': 'Bỏ qua', 'en': 'Skip'},
    'onboardingStart': {'vi': 'Bắt đầu', 'en': 'Get started'},
    'onboardingNext': {'vi': 'Tiếp', 'en': 'Next'},
    'onboardingSlide1Title': {'vi': 'Ghi âm dễ dàng', 'en': 'Easy recording'},
    'onboardingSlide1Body': {
      'vi': 'Bấm nút, nói vài câu — app ghi lại giọng của bạn ngay trên máy.',
      'en': 'Tap the button, say a few lines — the app records your voice right on the device.'
    },
    'onboardingSlide2Title': {
      'vi': 'Hàng loạt hiệu ứng vui',
      'en': 'Lots of fun effects'
    },
    'onboardingSlide2Body': {
      'vi': 'Robot, Alien, Nam trầm, Trẻ em, Ma quái... và còn nhiều nữa.',
      'en': 'Robot, Alien, Deep male, Child, Ghost... and many more.'
    },
    'onboardingSlide3Title': {'vi': 'Lưu và chia sẻ', 'en': 'Save and share'},
    'onboardingSlide3Body': {
      'vi': 'Nghe đối chiếu bản gốc và bản đã đổi, rồi lưu vào thư viện hoặc chia sẻ cho bạn bè.',
      'en': 'Compare the original and the changed take, then save it to the library or share it with friends.'
    },
    'onboardingMicTitle': {'vi': 'Cần quyền micro', 'en': 'Microphone needed'},
    'onboardingMicBody': {
      'vi': 'VoiceMorph cần micro để ghi âm. Bạn có thể bật lại bất cứ lúc nào trong Cài đặt.',
      'en': 'VoiceMorph needs the microphone to record. You can turn it back on any time in Settings.'
    },

    // Paywall
    'paywallTitle': {'vi': 'VoiceMorph PRO', 'en': 'VoiceMorph PRO'},
    'paywallSubtitle': {
      'vi': 'Mở khóa toàn bộ hiệu ứng và tắt quảng cáo.',
      'en': 'Unlock every effect and turn off ads.'
    },
    'paywallBenefit1': {
      'vi': 'Mở tất cả 12 hiệu ứng, kể cả Nam trầm và Ma quái',
      'en': 'Unlock all 12 effects, including Deep Male and Ghost'
    },
    'paywallBenefit2': {
      'vi': 'Không còn quảng cáo trong app',
      'en': 'No more ads in the app'
    },
    'paywallBenefit3': {
      'vi': 'Mọi tính năng mới của PRO sau này',
      'en': 'All future PRO features'
    },
    'paywallBuy': {'vi': 'Mua PRO — sắp có', 'en': 'Buy PRO — coming soon'},
    'paywallBuyNote': {
      'vi': 'Phần thanh toán đang được thiết lập, sẽ mở mua trong bản cập nhật tới.',
      'en': 'Payments are still being set up and will open in a coming update.'
    },
    'paywallRewarded': {
      'vi': 'Xem quảng cáo để mở hiệu ứng này 24 giờ',
      'en': 'Watch an ad to unlock this effect for 24 hours'
    },
    'paywallRewardedDone': {
      'vi': 'Đã mở hiệu ứng trong 24 giờ. Chúc vui!',
      'en': 'Unlocked for 24 hours. Have fun!'
    },
    'paywallRewardedFailed': {
      'vi': 'Chưa xem xong quảng cáo nên chưa mở được hiệu ứng.',
      'en': 'The ad was not finished, so the effect was not unlocked.'
    },
    'paywallUnlockedFor': {
      'vi': 'Đã mở hiệu ứng này đến {d}.',
      'en': 'This effect is unlocked until {d}.'
    },

    // Settings
    'settingsTitle': {'vi': 'Cài đặt', 'en': 'Settings'},
    'settingsTheme': {'vi': 'Giao diện', 'en': 'Appearance'},
    'settingsThemeSystem': {'vi': 'Theo hệ thống', 'en': 'System'},
    'settingsThemeDark': {'vi': 'Tối', 'en': 'Dark'},
    'settingsThemeLight': {'vi': 'Sáng', 'en': 'Light'},
    'settingsExport': {'vi': 'Định dạng xuất mặc định', 'en': 'Default export format'},
    'settingsLanguage': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'settingsVietnamese': {'vi': 'Tiếng Việt', 'en': 'Tiếng Việt'},
    'settingsEnglish': {'vi': 'English', 'en': 'English'},
    'settingsResponsibleUse': {
      'vi': 'Sử dụng có trách nhiệm',
      'en': 'Responsible use'
    },
    'settingsPrivacy': {'vi': 'Chính sách riêng tư', 'en': 'Privacy policy'},
    'settingsPrivacyBody': {
      'vi': 'VoiceMorph xử lý mọi file âm thanh ngay trên điện thoại của bạn. '
          'App không tải bản ghi hay file đã đổi giọng lên máy chủ, không tạo tài khoản, '
          'không theo dõi bạn qua các app khác. Quảng cáo (AdMob) có thể thu thập dữ liệu '
          'theo chính sách của Google; tắt quảng cáo khi bạn mua PRO (sắp có).',
      'en': 'VoiceMorph processes all audio right on your phone. '
          'The app does not upload your recordings or changed voices to any server, '
          'does not create accounts, and does not track you across other apps. '
          'Ads (AdMob) may collect data under Google’s policies; ads turn off when you buy PRO (coming soon).'
    },
    'settingsClearData': {'vi': 'Xóa dữ liệu', 'en': 'Clear data'},
    'settingsClearTitle': {'vi': 'Xóa toàn bộ dữ liệu?', 'en': 'Clear all data?'},
    'settingsClearBody': {
      'vi': 'Mọi bản đã lưu trong thư viện và file tạm sẽ bị xóa khỏi máy. Cài đặt và trạng thái PRO giữ nguyên.',
      'en': 'Every saved take in the library and all temporary files will be removed from the device. Settings and PRO status stay as they are.'
    },
    'settingsClearDone': {
      'vi': 'Đã xóa dữ liệu thư viện.',
      'en': 'Library data cleared.'
    },
    'settingsAbout': {'vi': 'Về ứng dụng', 'en': 'About'},
    'settingsAboutBody': {
      'vi': 'VoiceMorph — đổi giọng trên máy bằng hiệu ứng DSP.',
      'en': 'VoiceMorph — change your voice on-device with DSP effects.'
    },
    'settingsVersion': {'vi': 'Phiên bản', 'en': 'Version'},

    // Responsible use
    'responsibleTitle': {
      'vi': 'Sử dụng có trách nhiệm',
      'en': 'Use responsibly'
    },
    'responsibleBody': {
      'vi': 'VoiceMorph là app đổi giọng để vui: làm clip, lồng tiếng, troll bạn bè.\n\n'
          '• Đừng giả giọng người thật để lừa người khác.\n'
          '• Đừng dùng giọng đã đổi để quấy rối, dọa nạt hay lừa đảo.\n'
          '• Đừng ghi âm người khác khi họ không đồng ý.\n\n'
          'Bạn chịu trách nhiệm cho những gì mình chia sẻ.',
      'en': 'VoiceMorph is a voice changer for fun: clips, voice-overs, pranks with friends.\n\n'
          '• Do not imitate a real person’s voice to deceive others.\n'
          '• Do not use a changed voice to harass, threaten, or scam.\n'
          '• Do not record other people without their consent.\n\n'
          'You are responsible for what you share.'
    },

    // Banner placeholder (chỉ hiện ở bản dev khi chưa nạp được quảng cáo)
    'adsBannerPlaceholder': {
      'vi': 'Quảng cáo banner (đang tải / không có quảng cáo)',
      'en': 'Banner ad (loading / no ad available)'
    },

    // Lỗi FFmpeg (hiện trong snackbar khi import/xuất lỗi)
    'ffmpegFileNotFound': {
      'vi': 'Không tìm thấy file vừa chọn. Chọn lại file khác nhé.',
      'en': 'The selected file was not found. Please choose another file.'
    },
    'ffmpegFileEmpty': {
      'vi': 'File vừa chọn rỗng (0 byte), không giải mã được.',
      'en': 'The selected file is empty (0 bytes) and cannot be decoded.'
    },
    'ffmpegUnsupportedFormat': {
      'vi': 'Định dạng .{ext} chưa hỗ trợ. App nhận WAV, MP3 và M4A.',
      'en': 'The .{ext} format is not supported. The app accepts WAV, MP3 and M4A.'
    },
    'ffmpegDecodeFailed': {
      'vi': 'Không giải mã được file này. File có thể đã hỏng hoặc dùng codec không hỗ trợ — thử file khác hoặc xuất lại file từ app gốc nhé.',
      'en': 'This file could not be decoded. It may be damaged or use an unsupported codec — try another file or re-export it from the original app.'
    },
    'ffmpegNoRendered': {
      'vi': 'Chưa có file đã render để xuất. Xử lý lại một bản rồi xuất nhé.',
      'en': 'There is no rendered file to export yet. Process a take first.'
    },
    'ffmpegEncodeFailed': {
      'vi': 'Không xuất được file {fmt}. Kiểm tra dung lượng trống còn lại rồi thử lại nhé.',
      'en': 'Could not export the {fmt} file. Check the remaining free space and try again.'
    },

    // AI Voices
    'aiTitle': {'vi': 'Giọng AI — sắp ra mắt', 'en': 'AI Voices — coming soon'},
    'aiBody': {
      'vi': 'Giọng AI đổi danh tính giọng nói sẽ là một module riêng ở bản sau. '
          'Hiện tại app chỉ đổi giọng bằng hiệu ứng DSP chạy ngay trên máy, không cần mạng.',
      'en': 'AI voices that change your voice identity will be a separate module in a later release. '
          'For now the app only changes voices with on-device DSP effects, no network needed.'
    },
  };

  static String lookup(String languageCode, String key,
      [Map<String, String>? params]) {
    final lang = _values[key];
    var text = lang?[languageCode] ?? lang?['vi'] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }
}

/// Đối tượng localization của app, đọc chuỗi từ [AppStrings].
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  String t(String key, [Map<String, String>? params]) =>
      AppStrings.lookup(locale.languageCode, key, params);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(loc != null, 'AppLocalizations chưa được đăng ký delegate.');
    return loc!;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'vi' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
