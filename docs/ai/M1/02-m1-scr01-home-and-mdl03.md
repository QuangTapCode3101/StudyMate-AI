# Phiên làm việc AI #02: Chuyển đổi Học liệu PDF sang JSON Datasheet & SeedDataService

- **Thành viên:** M1 (Quảng) — Project Lead & Flutter Architect
- **Phạm vi:** Khởi tạo 10 bảng SQLite + `SeedDataService`
- **Công cụ AI:** Google Gemini

## 1. Vấn đề đặt ra cho AI
- Ứng dụng đi theo kiến trúc **Offline-first**: ngay khi cài APK lần đầu (chưa cần gọi API hay tự nạp tài liệu), người dùng cần có sẵn bộ dữ liệu mẫu chất lượng (môn Lập trình Flutter, các chủ đề, câu hỏi Quiz và Flashcard) để trải nghiệm ngay.
- Cần chuyển đổi dữ liệu thô từ tài liệu PDF thành định dạng JSON datasheet sạch, chuẩn hóa cấu trúc để `SeedDataService` nạp tự động vào SQLite.

## 2. Đề xuất của AI & Phản biện kỹ thuật
- **Quy trình chuẩn hóa:**
  - Trích xuất nội dung từ PDF, làm sạch các lỗi xuống dòng/ký tự rác và ánh xạ sang schema JSON tương thích trực tiếp với các bảng SQLite (`subjects`, `topics`, `questions`, `flashcards`...).
  - Thiết kế `SeedDataService` kiểm tra trạng thái DB trước khi nạp (chỉ seed khi cơ sở dữ liệu trống để tránh ghi đè hoặc nhân bản dữ liệu học tập của người dùng).
- **Quyết định kiến trúc liên quan đến SQLite:**
  - Khi cần lưu thêm cấu hình nhỏ (như `user_display_name`), AI phản biện không nên thêm bảng mới vào SQLite ở giai đoạn sát ngày build APK vì rủi ro crash `no such table` nếu thiếu migration `onUpgrade`; chuyển sang dùng `shared_preferences` độc lập.

## 3. Kết quả áp dụng & Kiểm chứng
- Hoàn thiện bộ JSON datasheet mẫu và tích hợp vào `DatabaseHelper.instance.seedDemoFlutterCourse()` / `SeedDataService`.
- Kiểm thử thực tế trên thiết bị: xóa dữ liệu app, mở lại từ đầu xác nhận dữ liệu mẫu nạp thành công, hiển thị đầy đủ trên Home, Thư viện và Luyện tập Quiz.