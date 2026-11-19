StudyMate AI

Ứng dụng hỗ trợ học tập lập trình trên thiết bị di động (Flutter) kết hợp AI, giúp sinh viên tải lên học liệu (PDF, Markdown, Source Code), tự động trích xuất chủ đề kiến thức, luyện tập trắc nghiệm (Quiz) và ôn tập thẻ ghi nhớ theo thuật toán lặp lại ngắt quãng (Spaced Repetition SM-2).

1. Mục đích dự án

Quản lý học liệu tập trung: Phân loại tài liệu theo môn học và ngôn ngữ lập trình.

Tóm tắt & bóc tách kiến thức bằng AI: Trích xuất nội dung văn bản từ PDF/Markdown/Code và sinh danh sách chủ đề trọng tâm.

Ôn tập chủ động: Hỗ trợ làm bài trắc nghiệm (nhận diện khái niệm, tìm lỗi, dự đoán output) và ôn tập Flashcard theo thuật toán SM-2.

Ưu tiên ngoại tuyến (Offline-first): Toàn bộ dữ liệu học tập được lưu cục bộ trên thiết bị, chỉ cần mạng khi gọi các tính năng phân tích AI.

2. Yêu cầu môi trường & Cài đặt

Yêu cầu

Flutter SDK (kênh stable, Dart 3.x)

Node.js (>= 18.x) và npm

Android Studio / Android SDK (có adb nếu chạy trên thiết bị Android thật)

Cấu trúc thư mục

studymate-ai/
├── mobile/          # Ứng dụng Flutter (UI, SQLite, PDF Extractor, SM-2)
├── backend/         # Backend Node.js (Proxy gọi Gemini API, quản lý quota)
└── .github/         # GitHub Actions CI (flutter analyze & flutter test)


Cài đặt thư viện

Backend:

cd backend
npm install


Mobile (Flutter):

cd mobile
flutter pub get


3. Cấu hình (Không chứa khóa bí mật)

Ứng dụng không lưu khóa API trong mã nguồn Flutter. Toàn bộ khóa được giữ tại Backend thông qua biến môi trường.

Tạo file .env trong thư mục backend/ dựa trên file mẫu .env.example:

cp backend/.env.example backend/.env


Điền giá trị vào backend/.env (file này đã nằm trong .gitignore, tuyệt đối không commit):

PORT=3000
GEMINI_API_KEY=<nhap_gemini_api_key_cua_ban>
USE_MOCK_AI=false


USE_MOCK_AI=true: Chạy chế độ dữ liệu giả lập (không tốn quota Gemini).

USE_MOCK_AI=false: Gọi trực tiếp Gemini API.

Cấu hình địa chỉ Backend phía Flutter:

Máy ảo Android (Emulator): http://10.0.2.2:3000

Thiết bị Android thật cắm qua USB (dùng adb reverse): http://127.0.0.1:3000

4. Cách chạy ứng dụng

Bước 1: Khởi động Backend

cd backend
npm start


Kiểm tra server hoạt động tại http://127.0.0.1:3000.

Bước 2: Chạy ứng dụng Flutter

Trên máy ảo (Emulator):

cd mobile
flutter run


Trên điện thoại Android thật (cắm cáp USB, đã bật USB Debugging):
Mở đường hầm cổng 3000 từ điện thoại về máy tính trước khi chạy app:

adb reverse tcp:3000 tcp:3000
cd mobile
flutter run


5. Cách chạy kiểm thử & Phân tích tĩnh (CI)

Dự án tích hợp GitHub Actions tự động chạy kiểm tra cho mỗi Pull Request vào develop và main. Để chạy kiểm tra tương tự ở máy cục bộ:

cd mobile

# Kiểm tra phân tích tĩnh (lỗi & cảnh báo)
flutter analyze --fatal-warnings

# Chạy toàn bộ unit test & widget test (bao gồm thuật toán SM-2)
flutter test


6. Dữ liệu được lưu ở đâu?

Cơ sở dữ liệu cục bộ (SQLite): Lưu trực tiếp trên bộ nhớ trong của thiết bị thông qua gói sqflite (DatabaseHelper), gồm các bảng chính:

subjects: Danh sách môn học và ngôn ngữ lập trình.

documents & document_chunks: Thông tin tài liệu và các đoạn văn bản đã trích xuất từ PDF/Markdown/Code.

topics: Các chủ đề kiến thức thuộc từng tài liệu.

quiz_questions / Flashcards: Ngân hàng câu hỏi trắc nghiệm và trạng thái ôn tập SM-2 (repetition, interval, ease_factor, next_review_at).

Dữ liệu khởi tạo (Seed Data): Lưu trong mobile/assets/seed/ (ví dụ bộ 300 câu hỏi trắc nghiệm Flutter song ngữ) và được nạp tự động 1 lần khi cơ sở dữ liệu trống.

Backend: Đóng vai trò trung gian (stateless proxy) tiếp nhận nội dung văn bản đã cắt đoạn, gọi Gemini API và trả JSON về cho ứng dụng; không lưu trữ vĩnh viễn tài liệu của người dùng.

7. Dùng AI (AI Usage Disclosure)

7.1. AI tích hợp trong sản phẩm

Mô hình: Google Gemini API, được gọi gián tiếp qua Backend Node.js để bảo vệ API key.

Chức năng: Phân tích các đoạn văn bản (chunks) từ học liệu do người dùng tải lên để tóm tắt nội dung và gợi ý danh sách chủ đề kiến thức.

Kiểm soát đầu ra: Dữ liệu AI trả về được xem như dữ liệu chưa kiểm chứng; ứng dụng hiển thị màn hình xem trước (Preview) cho phép người dùng sửa tên, thêm hoặc xóa chủ đề trước khi lưu vào SQLite.

7.2. AI hỗ trợ trong quá trình phát triển

Phạm vi sử dụng: Hỗ trợ rà soát code (code review), tìm nguyên nhân lỗi kết nối mạng/SQLite, thiết kế cấu hình GitHub Actions CI, và viết script làm sạch dữ liệu seed.

Kiểm chứng: Mọi đoạn mã và cấu hình do AI gợi ý đều được thành viên trong nhóm đọc hiểu, chạy kiểm thử cục bộ (flutter analyze, flutter test), và xác minh trực tiếp trên thiết bị thật trước khi merge vào nhánh 

