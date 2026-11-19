# Phiên làm việc AI #01: Cấu hình Hệ thống & Quota (MDL-03) và Đóng gói APK

- **Thành viên:** M1 (Quảng) — Project Lead & Flutter Architect
- **Phạm vi:** MDL-03 (System Config & Quota), Core Infrastructure
- **Công cụ AI:** Google Gemini

## 1. Vấn đề đặt ra cho AI
- Cần thiết kế cơ chế cho phép người dùng/giảng viên kiểm tra trạng thái kết nối Backend Node.js, cấu hình `Backend Base URL` linh hoạt và theo dõi/reset hạn mức gọi AI (20 lượt/ngày) ngay trên ứng dụng.
- Đánh giá rủi ro khi đóng gói bản `app-release.apk` độc lập (không cắm cáp chạy `adb reverse` hay trỏ `127.0.0.1` / `10.0.2.2`).

## 2. Đề xuất của AI & Phản biện kỹ thuật
- **Thiết kế MDL-03:**
  - Hiển thị `RateLimitBadge` (`Offline • 20/20` hoặc `Online • X/20`) trên góc phải màn hình Home.
  - Mở Bottom Sheet `_showServerConfigModal` cho phép sửa `Backend Base URL` qua `ApiClient.instance.setBaseUrl(...)`, kiểm tra `/api/v1/quota/status` và reset lượt qua `/api/v1/quota/reset`.
- **Phản biện & Rủi ro AI chỉ ra:**
  1. Nếu build APK release mà vẫn hardcode `10.0.2.2:3000`, tính năng AI sẽ chết khi cài lên máy thật. Cần truyền URL qua `--dart-define=API_BASE_URL=...` và lưu ý `android:usesCleartextTraffic="true"` nếu dùng HTTP nội bộ.
  2. Trong `_showServerConfigModal`, việc tạo `TextEditingController` bên ngoài `showModalBottomSheet` và gọi `controller.dispose()` ngay sau `await` tiềm ẩn lỗi vòng đời widget khi đóng modal lúc bàn phím đang mở.

## 3. Kết quả áp dụng & Kiểm chứng
- Đã tích hợp hoàn chỉnh `RateLimitBadge` và `_showServerConfigModal` nối với `HomeViewModel` (`refreshQuotaStatus`, `resetBackendQuota`).
- Cập nhật `README.md` tách rõ 2 luồng: dùng Offline (SQLite, Quiz, Flashcard SM-2) và luồng Online gọi Backend AI.