Markdown
# StudyMate AI

Ứng dụng hỗ trợ học tập lập trình trên thiết bị di động (Flutter) kết hợp AI, giúp sinh viên tải lên học liệu (PDF, Markdown, Source Code), tự động trích xuất chủ đề kiến thức, hỏi đáp cùng AI Tutor, luyện tập trắc nghiệm (Quiz) và ôn tập thẻ ghi nhớ theo thuật toán lặp lại ngắt quãng (Spaced Repetition SM-2).

## 1. Mục đích & Tính năng chính

* **Quản lý học liệu tập trung:** Phân loại tài liệu (PDF, Markdown, Source Code) theo môn học và ngôn ngữ lập trình.
* **Tóm tắt & bóc tách kiến thức bằng AI:** Trích xuất nội dung văn bản từ học liệu và sinh danh sách chủ đề trọng tâm.
* **AI Tutor theo ngữ cảnh:** Hỗ trợ giải thích khái niệm cơ bản, cơ chế hoạt động và so sánh khái niệm bám sát từng chủ đề học tập.
* **Ôn tập chủ động & Phân tích năng lực:** Luyện tập trắc nghiệm (nhận diện khái niệm, tìm lỗi, dự đoán output), tạo Flashcard từ câu làm sai theo thuật toán SM-2 và theo dõi bản đồ độ thông thạo (Analytics Dashboard).
* **Quản lý tài khoản & Quota AI:** Xác thực người dùng bằng JWT và kiểm soát hạn mức gọi AI theo ngày.
* **Ưu tiên ngoại tuyến (Local-first cho dữ liệu học tập):** Dữ liệu học tập được lưu cục bộ trên thiết bị giúp truy xuất nhanh và ôn tập offline; chỉ cần kết nối mạng khi đăng nhập hoặc gọi các tính năng AI.

## 2. Yêu cầu môi trường & Cài đặt

### Yêu cầu
* Flutter SDK (kênh `stable`, Dart 3.x)
* Node.js (>= 18.x) và npm
* Android Studio / Android SDK (có `adb` nếu chạy trên thiết bị Android thật)

### Cấu trúc thư mục
```text
studymate-ai/
├── mobile/          # Ứng dụng Flutter (UI, SQLite, PDF Extractor, SM-2, Auth)
├── backend/         # Backend Node.js (JWT Auth, Quota, PostgreSQL, Proxy gọi Gemini API)
└── .github/         # GitHub Actions CI (flutter analyze & flutter test)
Cài đặt thư viện
Backend:

Bash
cd backend
npm install
Mobile (Flutter):

Bash
cd mobile
flutter pub get
3. Cấu hình (Không chứa khóa bí mật)
Ứng dụng không lưu khóa API trong mã nguồn Flutter. Toàn bộ khóa bí mật được giữ tại Backend thông qua biến môi trường.

Tạo file .env trong thư mục backend/ dựa trên file mẫu .env.example:

Bash
cp backend/.env.example backend/.env
Điền giá trị vào backend/.env (file này đã nằm trong .gitignore, tuyệt đối không commit):

Đoạn mã
PORT=3000
DATABASE_URL=<postgres_connection_string_neon>
JWT_SECRET=<nhap_chuoi_bi_mat_jwt>
GEMINI_API_KEY=<nhap_gemini_api_key_cua_ban>
USE_MOCK_AI=false
USE_MOCK_AI=true: Chạy chế độ dữ liệu giả lập (không tốn quota Gemini).

USE_MOCK_AI=false: Gọi trực tiếp Gemini API.

Cấu hình địa chỉ Backend phía Flutter:

Cấu hình địa chỉ Backend phía Flutter:
* **Môi trường Cloud (Mặc định):** Cấu hình tại `ApiClient.defaultBaseUrl` trong file `mobile/lib/core/network/api_client.dart`, hiện đang trỏ sẵn về `https://backend-divine-moonbeam-7921.fly.dev`.
* **Môi trường Local (Phát triển):** Đổi `defaultBaseUrl` trong `mobile/lib/core/network/api_client.dart` (hoặc cấu hình trong ứng dụng qua `SharedPreferences`) sang:
  * Máy ảo Android (Emulator): `http://10.0.2.2:3000`
  * Thiết bị Android thật cắm qua USB (dùng `adb reverse`): `http://127.0.0.1:3000`

4. Cách chạy ứng dụng
Cách 1: Chạy nhanh với Backend Cloud (Khuyên dùng)
Bash
cd mobile
flutter run
Cách 2: Chạy kèm Backend Local
Bước 1: Khởi động Backend

Bash
cd backend
npm start
Kiểm tra server hoạt động tại http://127.0.0.1:3000.

Bước 2: Chạy ứng dụng Flutter

Trên máy ảo (Emulator):

Bash
cd mobile
flutter run
Trên điện thoại Android thật (cắm cáp USB, đã bật USB Debugging):

Bash
adb reverse tcp:3000 tcp:3000
cd mobile
flutter run
5. Cách chạy kiểm thử & Phân tích tĩnh (CI)
Dự án tích hợp GitHub Actions tự động chạy kiểm tra cho mỗi Pull Request vào develop và main. Để chạy kiểm tra tương tự ở máy cục bộ:

Bash
cd mobile

# Kiểm tra phân tích tĩnh (lỗi & cảnh báo)
flutter analyze --fatal-warnings

# Chạy toàn bộ unit test & widget test (bao gồm thuật toán SM-2)
flutter test
6. Kiến trúc lưu trữ dữ liệu (Hybrid Architecture)
Cơ sở dữ liệu cục bộ (SQLite - sqflite): Lưu trực tiếp trên bộ nhớ trong của thiết bị (DatabaseHelper) để đảm bảo tốc độ và hỗ trợ ôn tập ngoại tuyến, gồm các bảng chính:

subjects: Danh sách môn học và ngôn ngữ lập trình.

documents & document_chunks: Thông tin tài liệu và các đoạn văn bản đã trích xuất từ PDF/Markdown/Code.

topics: Các chủ đề kiến thức thuộc từng tài liệu và điểm độ thông thạo.

quiz_questions & quiz_attempts: Ngân hàng câu hỏi trắc nghiệm và lịch sử làm bài.

flashcards: Thẻ ghi nhớ và trạng thái ôn tập SM-2 (repetition, interval, ease_factor, next_review_at).

Dữ liệu khởi tạo (Seed Data): Lưu trong mobile/assets/seed/ (ví dụ bộ 300 câu hỏi trắc nghiệm Flutter song ngữ) và được nạp tự động 1 lần khi cơ sở dữ liệu trống.

Cơ sở dữ liệu Cloud (PostgreSQL trên Neon qua Backend Fly.io): Lưu trữ thông tin tài khoản người dùng (xác thực JWT), gói sử dụng và hạn mức gọi AI (Quota). Backend đóng vai trò trung gian gọi Gemini API và không lưu trữ vĩnh viễn nội dung tài liệu học tập của người dùng.

7. Dùng AI (AI Usage Disclosure)
7.1. AI tích hợp trong sản phẩm
Mô hình: Google Gemini API, được gọi gián tiếp qua Backend Node.js để bảo vệ API key và kiểm soát quota.

Chức năng:

Phân tích các đoạn văn bản (chunks) từ học liệu người dùng tải lên để tóm tắt nội dung và gợi ý danh sách chủ đề kiến thức.

Vận hành AI Tutor giải đáp kiến thức lập trình theo ngữ cảnh chủ đề.

Kiểm soát đầu ra: Dữ liệu AI trả về được xem như dữ liệu chưa kiểm chứng; ứng dụng hiển thị màn hình xem trước (Preview) cho phép người dùng sửa tên, thêm hoặc xóa chủ đề trước khi lưu vào SQLite.

7.2. AI hỗ trợ trong quá trình phát triển
Phạm vi sử dụng: Hỗ trợ rà soát code (code review), tìm nguyên nhân lỗi kết nối mạng/SQLite, thiết kế cấu hình GitHub Actions CI, và viết script làm sạch dữ liệu seed.

Kiểm chứng: Mọi đoạn mã và cấu hình do AI gợi ý đều được thành viên trong nhóm đọc hiểu, chạy kiểm thử cục bộ (flutter analyze --fatal-warnings, flutter test), và xác minh trực tiếp trên thiết bị thật trước khi merge vào nhánh main.


