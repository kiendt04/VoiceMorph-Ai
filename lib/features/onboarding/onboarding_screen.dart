import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/strings.dart';
import 'onboarding_flag.dart';

/// Onboarding 3 trang + xin quyền mic ở trang cuối.
/// - Được cấp quyền -> vào Home.
/// - Từ chối thường -> vẫn vào Home (màn Record sẽ hỏi lại khi cần).
/// - Từ chối vĩnh viễn -> hiện nút mở Cài đặt hệ thống, rồi vẫn vào Home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;
  var _requesting = false;

  // Tiêu đề/nội dung slide lấy theo ngôn ngữ trong build (không để
  // const vì AppLocalizations cần BuildContext).
  List<(IconData, String, String)> _slides(AppLocalizations s) => [
        (Icons.mic, s.t('onboardingSlide1Title'), s.t('onboardingSlide1Body')),
        (Icons.tune, s.t('onboardingSlide2Title'), s.t('onboardingSlide2Body')),
        (Icons.share, s.t('onboardingSlide3Title'), s.t('onboardingSlide3Body')),
      ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final s = AppLocalizations.of(context);
    if (_requesting) return;
    setState(() => _requesting = true);
    // Lỗi platform channel (kể cả trong test không có mock) cũng không
    // được chặn luồng: coi như chưa cấp quyền, màn Record sẽ hỏi lại.
    // Không đặt timeout: hộp thoại xin quyền của hệ thống chờ người dùng bấm.
    PermissionStatus? result;
    try {
      final status = await Permission.microphone.status;
      result = status.isGranted ? status : await Permission.microphone.request();
    } catch (_) {
      result = null;
    }
    final granted = result?.isGranted ?? false;
    if (!granted) {
      if (result != null && result.isPermanentlyDenied && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(s.t('onboardingMicTitle')),
            content: Text(s.t('onboardingMicBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.t('later')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Text(s.t('recordOpenSettings')),
              ),
            ],
          ),
        );
      }
    }
    await OnboardingFlag.markDone();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final slides = _slides(s);
    final last = _page == slides.length - 1;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _finish, child: Text(s.t('onboardingSkip'))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final (icon, title, body) = slides[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 96),
                      const SizedBox(height: 32),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requesting
                    ? null
                    : () {
                        if (last) {
                          _finish();
                        } else {
                          _pages.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                child: Text(last ? s.t('onboardingStart') : s.t('onboardingNext')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
