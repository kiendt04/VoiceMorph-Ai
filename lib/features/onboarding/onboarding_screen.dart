import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

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

  static const _slides = [
    (Icons.mic, 'Ghi âm dễ dàng',
        'Bấm nút, nói vài câu — app ghi lại giọng của bạn ngay trên máy.'),
    (Icons.tune, 'Hàng loạt hiệu ứng vui',
        'Robot, Alien, Nam trầm, Trẻ em, Ma quái... và còn nhiều nữa.'),
    (Icons.share, 'Lưu và chia sẻ',
        'Nghe đối chiếu bản gốc và bản đã đổi, rồi lưu vào thư viện hoặc chia sẻ cho bạn bè.'),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    // Lỗi platform channel (kể cả trong test không có mock) cũng không
    // được chặn luồng: coi như chưa cấp quyền, màn Record sẽ hỏi lại.
    // Timeout cũng vậy: nếu hộp thoại hệ thống/channel treo thì sau 2 giây
    // vẫn đi tiếp vào Home thay vì kẹt ở Onboarding.
    PermissionStatus? result;
    try {
      result = await (() async {
        final status = await Permission.microphone.status;
        return status.isGranted ? status : await Permission.microphone.request();
      })()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      result = null;
    }
    final granted = result?.isGranted ?? false;
    if (!granted) {
      if (result != null && result.isPermanentlyDenied && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cần quyền micro'),
            content: const Text(
              'VoiceMorph cần micro để ghi âm. Bạn có thể bật lại bất cứ lúc nào trong Cài đặt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Để sau'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Mở Cài đặt'),
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
    final last = _page == _slides.length - 1;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _finish, child: const Text('Bỏ qua')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final (icon, title, body) = _slides[index];
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
              for (var i = 0; i < _slides.length; i++)
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
                child: Text(last ? 'Bắt đầu' : 'Tiếp'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
