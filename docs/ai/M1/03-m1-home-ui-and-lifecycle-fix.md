# Phiên làm việc AI #03: Hoàn thiện Giao diện Home (SCR-01) & Xử lý Lỗi Vòng đời Widget

- **Thành viên:** M1 (Quảng) — Project Lead & Flutter Architect
- **Phạm vi:** SCR-01 (Home Dashboard), `HomeViewModel`
- **Công cụ AI:** Google Gemini

## 1. Vấn đề đặt ra cho AI
- Màn hình `HomeScreen` ban đầu đang fix cứng lời chào `"Chào Quảng! 👋"` và thông tin cá nhân tác giả, gây thiếu chuyên nghiệp khi nộp file APK cho người khác cài thử.
- Yêu cầu: Bỏ hardcode tên nhưng **không over-engineer** thêm hệ thống đăng nhập/tài khoản để giữ đúng triết lý Offline-first.

## 2. Đề xuất của AI & Các lỗi thực tế phát sinh khi kiểm chứng
- **Giải pháp ban đầu:** Tạo `UserPrefsService` dùng `shared_preferences`, nối vào `HomeViewModel` (đọc song song với SQLite bằng `Future.wait` để tránh rebuild 2 lần) và mở `AlertDialog` cho phép người dùng tự đổi tên.
- **Lỗi #1 — Crash màn hình đỏ `'_dependents.isEmpty': is not true`:**
  - *Nguyên nhân:* Code gợi ý ban đầu tạo `TextEditingController` bên ngoài `showDialog` và gọi `controller.dispose()` ngay sau `await showDialog`, trong khi animation đóng dialog (~150ms) chưa kết thúc và `TextField` vẫn còn trên cây widget.
  - *Cách sửa:* Tách nội dung dialog thành `StatefulWidget` riêng (`_EditNameDialog`) để Flutter tự gọi `dispose()` đúng vòng đời sau khi widget thực sự unmount.
- **Lỗi #2 — Tràn/cắt chữ `"Chào buổi chi..."` trên màn hình hẹp:**
  - *Nguyên nhân:* Đặt lời chào cỡ chữ lớn (22px) cùng hàng ngang với `RateLimitBadge` (`Offline • 20/20`) khiến chiều ngang không đủ.
  - *Cách sửa:* Tách Header thành **2 tầng** — tầng 1 gồm `vm.timeGreeting` (cỡ chữ nhỏ) ngang hàng với `RateLimitBadge`, tầng 2 gồm tên hiển thị full chiều ngang. Đưa logic `getTimeGreeting()` về đúng tầng `UserPrefsService` / `HomeViewModel` thay vì để ở `HomeScreen`.

## 3. Kết quả áp dụng & Kiểm chứng
- Đã kiểm thử thực tế trên thiết bị Android: bấm đổi tên, để trống tên, lưu và khởi động lại app không còn lỗi assertion hay cắt chữ.
- Chạy `flutter analyze` kiểm tra sạch lỗi cú pháp và cảnh báo thừa (`unused_element`).