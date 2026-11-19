# Nhật ký làm việc với AI (`docs/ai/`)

- **Dự án:** StudyMate-AI (Ứng dụng hỗ trợ học lập trình Flutter/Dart tích hợp AI Tutor)
- **Phạm vi công việc:**
  - Chuẩn hóa ánh xạ dữ liệu chủ đề (`topicId` $\rightarrow$ `topicName`) cho bộ câu hỏi trắc nghiệm.
  - **TASK-403 (Backend - Service & Controller):** Xây dựng và đồng bộ API sinh Mini-Quiz 3 câu (`generateMiniQuizFromTutor` & `POST /api/v1/quiz/generate-mini`) bám sát nội dung vừa hội thoại với AI Tutor.
  - **TASK-403 (Frontend Flutter - `TutorViewModel`):** Đồng bộ payload gửi API, truyền ngữ cảnh câu hỏi - câu trả lời (`userQuestion`, `tutorAnswer`), và khắc phục lỗi biên dịch Dart.

---

## 1. Xử lý ánh xạ `topicId` sang `topicName` trong dữ liệu câu hỏi (`flutter_300_questions_2.json`)

### Bối cảnh & Vấn đề
Tệp dữ liệu `flutter_300_questions.json` chứa danh sách `"topics"` (gồm `id` và `name` từ 1 đến 20) tách rời khỏi mảng `"questions"` (mỗi câu hỏi chỉ lưu `"topicId"`).

### Quyết định kỹ thuật
- **Phương án 1 (Khuyên dùng - Map tại tầng Flutter/SQLite):** Giữ nguyên cấu trúc JSON gọn nhẹ, tạo `Map<int, String> topicNameMap` khi parse JSON hoặc dùng `LEFT JOIN` giữa bảng `questions` và `topics` trong SQLite (`sqflite`) để tra cứu tên chủ đề với độ phức tạp $O(1)$.
- **Phương án 2 (Bổ sung trực tiếp vào JSON):** Sử dụng script Python để chèn trường `"topicName"` vào từng phần tử trong `"questions"` nếu backend/UI cần đọc trực tiếp.

---

## 2. Thiết kế & Đồng bộ Backend API cho Mini-Quiz (TASK-403)

### Vấn đề ban đầu
Hàm `geminiService.generateMiniQuizFromTutor` trước đây gọi lồng qua `generateQuiz` chung, dẫn đến việc AI dễ suy diễn kiến thức ngoài lề đoạn chat hoặc bị ép sinh `codeSnippet` gượng ép khi cuộc hội thoại chỉ đang thảo luận lý thuyết.

### Giải pháp đã triển khai

#### A. Service (`geminiService.generateMiniQuizFromTutor`)
- Tách thành lời gọi `ai.models.generateContent` độc lập với `systemInstruction` chuyên biệt:
  - Bắt buộc 3 câu hỏi phải bám sát trực tiếp nội dung `tutorAnswer` và `userQuestion` vừa trao đổi.
  - Chỉ sinh dạng `PREDICT_OUTPUT` hoặc `SPOT_BUG` kèm `codeSnippet` ($\le 12$ dòng, có đánh số dòng) khi đoạn giải thích của AI thực sự chứa ví dụ code.
  - Giảm `temperature` xuống `0.25` để hạn chế AI tự sáng tạo kiến thức ngoài phạm vi hội thoại.

#### B. Controller (`exports.generateMiniQuiz`)
- Cập nhật nhận đầy đủ các trường từ `req.body`: `programmingLanguage`, `topicId`, `topicName`, `userQuestion` (hoặc `question`), và `tutorAnswer` (hoặc `content`).
- Chuẩn hóa `safeTopicName` và `parsedTopicId`, trả về lỗi HTTP `400` (`INVALID_INPUT`) nếu thiếu `tutorAnswer`.

#### C. Dữ liệu JSON mẫu dùng để kiểm thử API (`POST /api/v1/quiz/generate-mini`)
```json
{
  "programmingLanguage": "Dart",
  "topicId": 12,
  "topicName": "Quản lý trạng thái (State Management)",
  "userQuestion": "Sự khác nhau giữa context.watch và context.read trong Provider là gì?",
  "tutorAnswer": "Trong gói Provider của Flutter, context.watch<T>() đăng ký lắng nghe sự thay đổi và tự động gọi lại build() khi state cập nhật (chỉ dùng trong build()). Ngược lại, context.read<T>() chỉ đọc giá trị 1 lần và không lắng nghe thay đổi, thường dùng trong onPressed."
}
```

---

## 3. Kiểm tra & Đồng bộ Frontend Flutter (`TutorViewModel` - TASK-403)

### Các xung đột đã phát hiện & khắc phục
1. **Lệch tên key trong request body (gây lỗi HTTP 400):**
   - `TutorViewModel.generateMiniQuiz` gửi key `'sourceContent'`, trong khi Backend chỉ đọc `'tutorAnswer'` hoặc `'content'`.
   - **Khắc phục:** Đổi sang gửi `'tutorAnswer': answerContent`, đồng thời bổ sung `'topicId': context.topicId` và tự động trích xuất `'userQuestion'` từ tin nhắn người dùng liền trước tin nhắn AI trong `_messages`.
2. **Lỗi biên dịch Dart (`The operator '>' isn't defined...` & `The method 'map' isn't defined...`):**
   - Do mất phần kiểu generic trong `.whereType<Map<String, dynamic>>()` khi sao chép code.
   - **Khắc phục:** Chuyển sang kiểm tra kiểu tường minh và ép kiểu an toàn để tránh phụ thuộc cú pháp generic lồng nhau:
     ```dart
     final questions = rawQuestions is List
         ? rawQuestions
             .where((e) => e is Map)
             .map((e) => MiniQuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
             .where((q) => q.isValid)
             .take(3)
             .toList()
         : <MiniQuizQuestion>[];
     ```