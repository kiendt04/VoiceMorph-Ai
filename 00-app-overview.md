# VoiceMorph – Mô tả ứng dụng

> Tên app là tên tạm, có thể đổi. Tài liệu này mô tả sản phẩm ở mức tổng quan; chi tiết kỹ thuật và thiết kế nằm trong các file liên quan ở mục 14.

---

## 1. Tóm tắt

**VoiceMorph** là ứng dụng di động (Flutter, Android và iOS) cho phép người dùng **ghi âm hoặc nhập file âm thanh, đổi giọng bằng các hiệu ứng có sẵn, tinh chỉnh thông số, nghe thử, rồi lưu và chia sẻ**.

Phiên bản đầu (MVP) xử lý theo kiểu **ghi âm rồi biến đổi** bằng kỹ thuật xử lý tín hiệu số (DSP): đổi cao độ, formant, tốc độ, thêm hiệu ứng như robot, vang, radio cũ. Các giai đoạn sau có thể thêm biến đổi giọng bằng AI chạy trên server và chế độ realtime.

**Một câu:** biến giọng của bạn thành giọng trầm, giọng robot, giọng alien... chỉ trong vài chạm, rồi gửi cho bạn bè.

---

## 2. Vấn đề và giá trị mang lại

| Nhu cầu của người dùng | VoiceMorph giải quyết bằng |
|---|---|
| Muốn tạo nội dung vui để gửi bạn bè, đăng mạng xã hội | Nhiều hiệu ứng giọng, chia sẻ nhanh sang Zalo, Messenger, Telegram |
| Muốn thử giọng khác nhau (trầm, cao, trẻ em, robot) | Thư viện preset, nghe thử ngay, chỉnh được từng tham số |
| Không biết dùng phần mềm âm thanh phức tạp | Luồng 3 bước đơn giản: ghi hoặc nhập, chọn hiệu ứng, lưu |
| Muốn giữ lại và dùng lại bản ghi | Thư viện bản ghi trong máy, xuất MP3/WAV, đặt nhạc chuông (Android) |

---

## 3. Đối tượng người dùng

- Người trẻ thích nội dung vui, làm clip ngắn, nhắn tin bằng voice.
- Người làm nội dung (TikTok, YouTube Shorts, podcast vui) cần đổi giọng nhanh.
- Người chơi game, nhóm bạn muốn trêu đùa nhau bằng giọng lạ.
- Người dùng phổ thông muốn thử một công cụ giải trí đơn giản.

Ứng dụng không nhắm đến việc mạo danh hay lừa đảo; xem mục 11.

---

## 4. Tính năng

### 4.1 MVP (hướng A – hiệu ứng DSP, xử lý offline)

| Nhóm | Tính năng |
|---|---|
| Nguồn âm thanh | Ghi âm trực tiếp; nhập file MP3, WAV, M4A |
| Hiệu ứng | 10–15 preset (Nam trầm, Nữ cao, Trẻ em, Người già, Robot, Alien, Ma quái, Hang động, Chipmunk, Radio cũ...) |
| Tinh chỉnh | Cao độ, formant, tốc độ, vang (reverb), echo; so sánh "Bản gốc" và "Đã đổi" |
| Nghe thử | Preview nhanh trước khi lưu; xem waveform |
| Lưu trữ | Thư viện bản ghi trong máy: đổi tên, xóa, tìm kiếm, yêu thích |
| Xuất và chia sẻ | Xuất MP3/AAC/WAV; chia sẻ qua các app; đặt nhạc chuông (Android) |
| Cài đặt | Ngôn ngữ Việt/Anh, giao diện sáng/tối, chất lượng xuất, xóa dữ liệu, chính sách quyền riêng tư |
| Kiếm tiền | Preset PRO, quảng cáo, gói đăng ký |
| Phân tích | Thống kê sử dụng và báo lỗi (Firebase) |

### 4.2 Mở rộng (làm sau MVP)

- **Giọng AI (hướng B/C):** chuyển đổi sang giọng nhân vật hoặc giọng đã được cấp phép, chạy trên server GPU; hoặc text-to-speech.
- **Realtime:** đổi giọng khi đang nói, dùng engine âm thanh gốc để giảm độ trễ.
- **Mở rộng nội dung:** thêm preset theo mùa, hiệu ứng âm thanh nền.
- **Tài khoản và đồng bộ:** sao lưu thư viện lên đám mây (nếu cần).

### 4.3 Ngoài phạm vi (không làm ở MVP)

- Đổi giọng khi gọi điện hoặc trong ứng dụng khác.
- Chỉnh sửa nhiều track hoặc dựng nhạc.
- Mạng xã hội trong app.

---

## 5. Luồng người dùng chính

```
Mở app → (lần đầu: Onboarding → xin quyền micro → cảnh báo dùng có trách nhiệm)
   ↓
Home → Ghi âm (hoặc Nhập file)
   ↓
Chọn hiệu ứng → Tinh chỉnh (tùy chọn) → Đang xử lý
   ↓
Kết quả → Lưu / Chia sẻ / Đặt nhạc chuông / Xuất file
   ↓
Thư viện (xem lại, nghe lại, xóa)
```

**Luồng phụ:**
- Chạm preset bị khóa (PRO) → Paywall.
- Quyền micro bị từ chối → hướng dẫn mở Cài đặt.
- Xử lý thất bại → màn lỗi, cho thử lại.

---

## 6. Danh sách màn hình

Tên frame trong Stitch khớp với `DESIGN.md`, và tên widget Flutter tương ứng.

| Ưu tiên | Tên frame | Màn hình |
|---|---|---|
| P0 | `P0-01_Home` | Trang chủ: nút ghi âm, nhập file, preset nổi bật, bản ghi gần đây |
| P0 | `P0-02_Recording` | Ghi âm: bộ đếm, waveform, điều khiển |
| P0 | `P0-03_ChooseEffect` | Chọn hiệu ứng: lưới preset, tìm kiếm, bộ lọc |
| P0 | `P0-04_FineTune` | Tinh chỉnh: waveform, so sánh gốc/đã đổi, các thanh trượt |
| P0 | `P0-05_Result` | Kết quả: nghe lại, lưu, chia sẻ, nhạc chuông, xuất |
| P0 | `P0-06_Library` (+ `_Empty`) | Thư viện bản ghi |
| P1 | `P1-01_Splash` | Màn khởi động |
| P1 | `P1-02_Onboarding_1/2/3` | Giới thiệu 3 trang |
| P1 | `P1-03_MicPermission` (+ `_Denied`) | Xin quyền micro |
| P1 | `P1-04_Import` (+ `_FileSelected`) | Nhập file âm thanh |
| P1 | `P1-05_Processing` (+ `_Failed`) | Đang xử lý, báo lỗi |
| P1 | `P1-06_Settings` | Cài đặt |
| P2 | `P2-01_Paywall` | Nâng cấp PRO |
| P2 | `P2-02_ResponsibleUse` | Cảnh báo dùng có trách nhiệm |
| P2 | `P2-03_AIVoices` | Giọng AI (khi có backend) |

Điều hướng chính: thanh dưới 3 tab: **Trang chủ, Thư viện, Cài đặt**.

---

## 7. Cách đổi giọng hoạt động (tóm tắt)

Giọng nói gồm cao độ (pitch), formant (âm sắc theo kích cỡ khoang miệng/họng), tốc độ và môi trường âm thanh. Mỗi **preset** là một chuỗi hiệu ứng chạy theo thứ tự:

```
Ghi âm / Nhập file
   ↓ chuẩn hóa (PCM 16-bit, 44.1kHz, mono)
   ↓ khử ồn (tùy chọn)
   ↓ pitch / formant → EQ → hiệu ứng (robot, tremolo) → echo / reverb
   ↓ limiter (chống vỡ tiếng)
   ↓ lưu WAV, xuất MP3/AAC
```

Preset lưu dạng dữ liệu (JSON), nên thêm hiệu ứng mới không cần sửa code. Xem chi tiết ở `06-core-voice-engine.md`.

---

## 8. Công nghệ

| Lớp | Lựa chọn |
|---|---|
| Ứng dụng | Flutter, Material 3, Riverpod, go_router |
| Ghi và phát | `record`, `just_audio`, `permission_handler`, `file_picker` |
| Xử lý âm thanh | FFmpeg (`ffmpeg_kit_flutter` hoặc bản fork còn bảo trì); nâng cao: SoundTouch / Rubber Band qua `dart:ffi` |
| Realtime (sau này) | Oboe/AAudio (Android), AVAudioEngine (iOS) |
| Lưu trữ | Isar hoặc Drift |
| Chia sẻ | `share_plus` |
| Kiếm tiền | AdMob, RevenueCat (`purchases_flutter`) |
| Phân tích và lỗi | Firebase Analytics, Crashlytics |
| AI (sau này) | Backend FastAPI + GPU (RVC hoặc tương đương), hàng đợi job, Firebase Auth |

---

## 9. Kiến trúc tổng quan

```
UI (Flutter, Material 3)
   ↓ Riverpod
Features: onboarding · home · record · effects · editor · result · library · settings · paywall
   ↓
Domain: Recording, EffectPreset, EffectNode, trạng thái bản ghi
   ↓
Data: AudioRecorderService · AudioPlayerService · RecordingRepository (Isar/Drift) · AssetStore
   ↓
Audio: AudioPipeline → VoiceEngine (interface)
                         ├─ FFmpegEngine       (MVP)
                         ├─ NativeFfiEngine    (chất lượng cao)
                         ├─ RealtimeEngine     (sau này)
                         └─ RemoteAiEngine     (sau này)
```

Tách `VoiceEngine` sau một interface để đổi hoặc thêm engine mà không ảnh hưởng giao diện.

---

## 10. Mô hình kiếm tiền

- **Miễn phí:** một phần preset cơ bản, xuất chất lượng chuẩn, có quảng cáo.
- **PRO (đăng ký tuần/tháng/năm):** mở toàn bộ preset, xuất chất lượng cao, bỏ quảng cáo, giọng AI khi có.
- **Quảng cáo:** banner ở Thư viện, interstitial sau khi lưu, rewarded để mở khóa preset tạm thời.

Giá gói và tỉ lệ ưu đãi do bạn quyết định khi đến bước kiếm tiền.

---

## 11. Quyền riêng tư, an toàn và pháp lý

- **Dữ liệu giọng nói là dữ liệu nhạy cảm** (ở nhiều nơi được coi là sinh trắc học). Ở MVP, âm thanh chỉ xử lý và lưu **trên máy người dùng**, không gửi lên server.
- Khi có tính năng AI chạy server: cần thông báo rõ, xin đồng ý, giới hạn thời gian lưu và cho phép xóa.
- Bắt buộc có **Chính sách quyền riêng tư** và **Điều khoản sử dụng** công khai; khai báo Data safety (Google Play) và Privacy labels (App Store).
- **Chống lạm dụng:** hiện cảnh báo "Dùng có trách nhiệm" ở lần đầu, không cung cấp giọng người nổi tiếng khi chưa có phép, có cơ chế báo cáo lạm dụng.
- Giọng AI chỉ dùng giọng đã được **chủ giọng đồng ý bằng văn bản**.
- Âm thanh nền và hiệu ứng âm thanh phải có giấy phép sử dụng thương mại.

---

## 12. Tiêu chí thành công (gợi ý)

| Chỉ số | Cách đo |
|---|---|
| Hoàn thành luồng cốt lõi | Tỉ lệ người dùng đi hết "ghi âm → chọn hiệu ứng → lưu/chia sẻ" |
| Chất lượng xử lý | Preset xử lý file 1 phút dưới 5 giây trên máy tầm trung, không vỡ tiếng |
| Độ ổn định | Tỉ lệ phiên không lỗi (Crashlytics) |
| Giữ chân | Người dùng quay lại sau 1 ngày, 7 ngày |
| Doanh thu | Tỉ lệ chuyển đổi sang PRO, doanh thu quảng cáo trên mỗi người dùng |

Mục tiêu cụ thể cho từng chỉ số nên đặt sau khi có dữ liệu beta.

---

## 13. Lộ trình dự kiến (1 người làm)

| Giai đoạn | Nội dung | Thời gian |
|---|---|---|
| 1 | Khởi tạo project, quyền, ghi âm, nhập file, phát lại | ~1 tuần |
| 2 | Engine xử lý âm thanh và preset | 1–2 tuần |
| 3 | Giao diện theo thiết kế, thư viện, xuất và chia sẻ, đa ngôn ngữ | 3–4 tuần |
| 4 | Kiếm tiền, analytics, ổn định | ~1 tuần |
| 5 | Test, phát hành | ~2 tuần |
| **MVP** | | **~8–10 tuần** |
| Sau MVP | Giọng AI, realtime | +4–8 tuần mỗi hạng mục |

---

## 14. Tài liệu liên quan

| File | Nội dung |
|---|---|
| `01-can-chuan-bi.md` | Việc cần chốt, dữ liệu cần chuẩn bị, công cụ, rủi ro |
| `02-cac-buoc-code.md` | 13 bước code tuần tự, tiêu chí hoàn thành từng bước |
| `03-prompt-design-frames.md` | Bản prompt thiết kế đầu tiên (đã được thay thế bởi file 04) |
| `04-stitch-prompts.md` | Prompt Stitch theo ưu tiên, tên frame chuẩn |
| `05-stitch-assets.md` | Prompt tạo icon, logo, ảnh minh họa; cách xuất và cấu hình Flutter |
| `06-core-voice-engine.md` | Phần lõi nghiệp vụ xử lý âm thanh đổi giọng |
| `DESIGN.md` | Design system để import vào Stitch |
