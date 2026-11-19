# Module AI Tutor (M3) – đoạn trao đổi quan trọng

Phần của tôi: Flutter cho module AI Tutor (giao diện, ViewModel, Repository, lưu SQLite, gọi API). Tôi chỉ ghi vào hai bảng `chat_sessions` và `chat_messages`, không sửa `lib/core` hay thư mục của thành viên khác. Trong hai đoạn dưới đây tôi có trao đổi với Claude để chốt hướng làm.

## 1. Xây dựng module AI Tutor (TASK-401, 402, 403)

**Vấn đề:** cần một màn hình hỏi đáp với AI mà câu trả lời hiện dần theo thời gian thực, có lịch sử chat, có nguồn trích dẫn và có bài kiểm tra nhanh sau mỗi câu trả lời.

**Cách giải quyết:**
- Nhận dữ liệu từ backend qua SSE, đọc từng sự kiện `chunk`, `done` và `error`.
- `TutorViewModel` giữ toàn bộ trạng thái chat. Khi lỗi thì hiện thông báo kèm nút **Thử lại**.
- Lưu phiên chat và tin nhắn vào SQLite để mở lại được lịch sử, có popup chọn phiên và chọn chủ đề.
- Câu trả lời được tách thành đoạn văn Markdown và khối code, khối code có thể cuộn ngang.
- Mỗi nguồn trích dẫn là một chip. Bấm vào chip mở popup xem nội dung gốc của đoạn tài liệu.
- Mini-quiz 3 câu gọi `/quiz/generate-mini`, hiện trong popup sau câu trả lời của AI.
- Có 5 nút gợi ý tương ứng 5 chế độ học: giải thích cơ bản, cơ chế, so sánh, giải thích code, lỗi thường gặp.

## 2. Bổ sung 3 tính năng theo góp ý của nhóm (18/11)

**Vấn đề:** nhóm muốn có nút dừng câu trả lời của AI, chỉnh sửa câu hỏi đã gửi, và cảnh báo khi mất mạng hoặc backend không chạy.

**Cách giải quyết:**
- **Dừng câu trả lời:** hủy luồng SSE đang nhận và giữ lại phần chữ đã nhận được, rồi lưu phần đó vào SQLite.
- **Chỉnh sửa câu hỏi:** cho sửa câu hỏi cuối cùng, sau đó gửi lại và thay câu trả lời cũ bằng câu trả lời mới.
- **Cảnh báo mất kết nối:** kiểm tra kết nối trước khi gửi bằng cách gọi thử `GET /quota/status`, vì lệnh này không tốn lượt AI. Nếu mất mạng hoặc backend không chạy thì hiện banner cảnh báo và khóa ô nhập.
- Các phần mới nằm trong thư mục của module (`services/connection_status.dart`, `services/internet_probe.dart`, `views/widgets/connection_banner.dart`), không đụng vào `lib/core`.