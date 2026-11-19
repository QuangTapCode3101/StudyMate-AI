# Hội thoại quan trọng với AI – M2 (Phạm Thế Mạnh)

Công cụ: Claude (Claude Code), dùng để gợi ý hướng làm và hỗ trợ viết code. Phạm vi: `mobile/lib/features/library/`.

## 1. AI gợi ý cách nối app với AI rút chủ đề của M5

**Mình hỏi AI:** cách để app gửi nội dung tài liệu lên server của M5 và nhận chủ đề về.

**AI gợi ý:**
- Đọc code server của M5 trước để app gửi đúng định dạng dữ liệu và xử lý đúng các lỗi (hết lượt, gửi quá nhanh, chưa nối Gemini).
- Không mở file `.env` của server vì có thể chứa khoá API.
- Trong lúc chờ Gemini thật, dùng dữ liệu mẫu của M5 qua một cờ bật/tắt.

**Mình làm:** Làm theo gợi ý, đọc lại định dạng dữ liệu của M5 cho khớp, và nhắn M5 để báo khi Gemini thật xong thì mình đổi cờ và thử lại.

## 2. AI gợi ý chạy thử thật trước khi nộp

**Mình hỏi:** "chưa chạy thử SCR-04 với server của M5. là sao"

**AI gợi ý:** Code mới qua kiểm tra tĩnh, chưa chắc đúng với server. Nên chạy server của M5 và app trên emulator rồi thử cả luồng.

**Mình làm:** Tự chạy server, thao tác trên emulator, và gửi lại ảnh màn hình ở từng bước để kiểm tra. Luồng phân tích ra chủ đề và lưu vào cơ sở dữ liệu chạy đúng. Trong lúc thử còn phát hiện lỗi hiển thị 1 pixel ở danh sách tài liệu và đã sửa.

**Mình học được:** AI chỉ gợi ý và viết nháp, mình phải chạy thật để kiểm chứng và tự hiểu code mình nộp.
