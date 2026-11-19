# BÁO CÁO ỨNG DỤNG TRỢ LÝ AI TRONG DỰ ÁN STUDYMATE-AI
## MILESTONE 4: MODULE QUIZ & FLASHCARDS (LUYỆN TẬP VÀ ÔN TẬP THÔNG MINH)

- **Sinh viên thực hiện**: Phạm Khánh Thiện (M4 Lead)
- **Mã nguồn nhánh (Branch)**: `M4_Thien`
- **Công cụ trợ lý AI**: Google Antigravity / Gemini (Coding Assistant chuyên sâu Flutter & Dart)
- **Chuẩn đánh giá tuân thủ**: Quy định "Dùng trợ lý AI" trong tài liệu *Chủ đề project Flutter và Rubric cuối kỳ*

---

## I. TỔNG QUAN CÔNG CỤ TRỢ LÝ AI ĐÃ SỬ DỤNG

Trong quá trình phát triển Module 4 (Quiz & Flashcards), trợ lý AI được tích hợp như một thành viên lập trình cặp (Pair-programmer) và kỹ sư kiểm thử (QA Engineer):
- **Tên công cụ**: **Google Antigravity** (sử dụng nền tảng mô hình ngôn ngữ lớn **Gemini 2.5 Flash & Gemini 2.5 Pro**).
- **Môi trường hoạt động**: Tích hợp trực tiếp vào môi trường phát triển (IDE), cho phép phân tích ngữ cảnh toàn diện dự án từ tài liệu đặc tả SRS ([app-StudyMate-AI.docx](file:///d:/StudyMate-AI/app-StudyMate-AI.docx)), kế hoạch chi tiết ([Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx](file:///d:/StudyMate-AI/Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx)) đến kiến trúc thư mục mã nguồn `mobile/lib/`.
- **Nguyên tắc cốt lõi**:
  - Không ủy thác hoàn toàn; người phát triển (sinh viên) giữ quyền kiểm soát và phê duyệt 100%.
  - Mọi dòng mã do AI sinh ra đều phải được sinh viên đọc hiểu, giải thích được logic, và chạy kiểm thử tự động (`flutter test`) cùng phân tích cú pháp tĩnh (`dart analyze`) trước khi đưa vào codebase.

---

## II. PHÂN ĐỊNH TRÁCH NHIỆM & MÔ HÌNH LÀM VIỆC (HUMAN-IN-THE-LOOP)

Mô hình làm việc giữa sinh viên (Phạm Khánh Thiện) và Trợ lý AI tuân thủ quy trình lặp 5 bước có kiểm soát:

```
[1. Yêu cầu & Đặc tả]  --->  [2. Lập kế hoạch /plan]  --->  [3. Sinh mã & Refactor]
 (Sinh viên định hướng)       (AI đề xuất cấu trúc)         (AI sinh code + Test)
                                                                   |
[5. Git Commit & Push] <---  [4. Review & Kiểm thử]    <-----------+
 (Sinh viên tự tay chạy)      (Sinh viên chạy test máy)
```

1. **Bước 1 - Định hình yêu cầu (Prompting có cấu trúc)**: Sinh viên cung cấp tài liệu nghiệp vụ, mô tả màn hình theo SRS (SCR-06 đến SCR-10), định dạng dữ liệu đầu vào và các tiêu chí bắt buộc.
2. **Bước 2 - Lập kế hoạch chi tiết (`/plan`)**: AI đề xuất danh sách file cần tạo/sửa, cấu trúc lớp (Models, Repositories, ViewModels, Views, Tests). Sinh viên duyệt hoặc yêu cầu chỉnh sửa cấu trúc trước khi viết code.
3. **Bước 3 - Sinh mã nguồn & bộ kiểm thử (Code Generation)**: AI hiện thực hóa các đoạn mã lặp lại (boilerplate MVVM), các thuật toán toán học (SM-2, grading), và thiết kế các unit test bao phủ các ca biên (edge cases).
4. **Bước 4 - Phân tích, hiểu mã và chạy thử (Verification & Review)**: Sinh viên chạy `flutter test` và `dart analyze` trên máy thật. Nếu có lỗi type hay linter, sinh viên cùng AI phân tích nguyên nhân gốc rễ và sửa đổi.
5. **Bước 5 - Quản lý phiên bản thủ công (Manual Git Management)**: Sinh viên tự tay stage file, kiểm tra loại trừ các file tài liệu Word/PDF, thực hiện commit theo chuẩn `feat(...)` và push lên nhánh `M4_Thien`.

---

## III. CHI TIẾT CÁC PHẦN MÃ NGUỒN ĐƯỢC AI HỖ TRỢ TRONG MILESTONE 4

| Giai đoạn & Mã Task | Module / Tệp nguồn cụ thể | Chi tiết nội dung AI hỗ trợ | Giá trị đóng góp của AI |
| :--- | :--- | :--- | :--- |
| **GĐ 1 & 2**<br>`TASK-501`<br>`TASK-504` | • `quiz_attempt_model.dart`<br>• `attempt_answer_model.dart`<br>• `flashcard_model.dart`<br>• `quiz_dto.dart`<br>• `IQuizRepository`<br>• `IFlashcardRepository` | • Xây dựng các Data Models với các trường tương thích 100% với SQLite schema trong `DatabaseHelper`.<br>• Viết các hàm chuyển đổi `toMap()`, `fromMap()`, `copyWith()`.<br>• Thiết lập Interface trừu tượng (Contract) cho tầng dữ liệu. | Chuẩn hóa tầng thực thể dữ liệu, đảm bảo type-safety, tránh lỗi sai kiểu dữ liệu SQLite. |
| **GĐ 3**<br>`TASK-503` | • `sm2_calculator.dart`<br>• `test/sm2_calculator_test.dart` | • Triển khai thuật toán SuperMemo SM-2 thuần Dart (Pure Dart), hoàn toàn không phụ thuộc Flutter framework.<br>• Viết 6 ca kiểm thử bao phủ toàn bộ dải đánh giá ($q \in [0, 5]$) và các trường hợp lặp đầu tiên, lặp lại, và quên kiến thức. | Đảm bảo tính toán khoảng thời gian lặp chính xác theo khoa học trí nhớ (Spaced Repetition). |
| **GĐ 4**<br>`TASK-501`<br>`TASK-502` | • `quiz_repository.dart`<br>• `quiz_viewmodel.dart`<br>• `quiz_setup_screen.dart` (SCR-06)<br>• `active_quiz_screen.dart` (SCR-07)<br>• `quiz_result_screen.dart` (SCR-08)<br>• `test/quiz_grading_test.dart` | • Thuật toán chấm điểm tự động hỗ trợ 5 dạng câu hỏi: Single choice, Multiple choice (so khớp Set), True/False, Fill in Blank, Short Answer (chuẩn hóa chuỗi bằng `.trim().toLowerCase()`).<br>• Bộ đếm ngược thời gian làm bài `Timer.periodic`.<br>• Lưu trữ lịch sử lần thi và chi tiết từng câu trả lời xuống SQLite. | Xử lý logic chấm điểm phức tạp và quản lý trạng thái luồng bài thi mượt mà theo kiến trúc MVVM. |
| **GĐ 5**<br>`TASK-504` | • `flashcard_repository.dart`<br>• `flashcard_viewmodel.dart`<br>• `flashcard_decks_tab.dart` (SCR-09)<br>• `flashcard_review_screen.dart` (SCR-10)<br>• `progress_screen.dart`<br>• `test/flashcard_flow_test.dart` | • Thiết kế hiệu ứng lật thẻ 3D dùng `AnimationController` kết hợp biến đổi không gian `Matrix4` với góc quay $180^\circ$ (`pi * value`).<br>• Gắn kết 4 mức đánh giá (Again, Hard, Good, Easy) kích hoạt trực tiếp hàm `Sm2Calculator` để cập nhật `nextReviewAt`.<br>• Thẻ thống kê tiến độ học tập. | Mang lại trải nghiệm người dùng sinh động, trực quan và chuẩn hóa theo các ứng dụng học tập hiện đại như Anki/Quizlet. |
| **Tối ưu & Linter** | Toàn bộ các file trong module M4 | • Khắc phục các cảnh báo deprecated của Flutter SDK.<br>• Thêm `const` constructors để tối ưu hóa hiệu năng render widget tree.<br>• Đạt kết quả phân tích tĩnh sạch tuyệt đối (`No issues found!`). | Mã nguồn sạch, đúng chuẩn Clean Code và quy chuẩn dự án. |

---

## IV. TRÍCH ĐOẠN HỘI THOẠI & PROMPT TIÊU BIỂU VỚI TRỢ LÝ AI

*Dưới đây là các câu lệnh Prompt **nguyên văn 100% của sinh viên (Phạm Khánh Thiện)** được trích xuất từ nhật ký tương tác thực tế với trợ lý AI, thể hiện vai trò làm chủ đề tài, phản biện kiến trúc và kiểm soát chặt chẽ quá trình phát triển mã nguồn:*

---

### 1. Phân rã yêu cầu và lập kế hoạch công việc theo tài liệu đặc tả SRS
- **Prompt nguyên văn của sinh viên**:
  > `ĐỌC HIỂU TOÀN BỘ DỰ ÁN NÀY CHO TÔI`
  > 
  > `TỔNG HỢP CHO TÔI NHỮNG YÊU CẦU CẦN LÀM CỦA M4 (tôi là người thực hiện code) VÀ DỰA VÀO tài liệu đặc tả đồ án (app-StudyMate-AI.docx) CHO TÔI BIẾT THỨ TỰ NHỮNG CÔNG VIỆC CẦN LÀM`
  > 
  > `TẠO MỘT FILE DOCX VỚI BẢNG CÔNG VIỆC CỦA M4 THEO THỜI GIAN DỰA VÀO FILE TÀI LIỆU ĐẶC TẢ ĐỒ ÁN (app-StudyMate-AI.docx)`
- **Phản hồi và đóng góp của AI**:
  - AI đọc toàn bộ tài liệu đặc tả `app-StudyMate-AI.docx`, trích xuất các màn hình thuộc phạm vi M4 (SCR-06 Setup, SCR-07 Active Quiz, SCR-08 Kết quả, SCR-09 Danh sách thẻ, SCR-10 Học thẻ lật).
  - Phân tích các mã Task từ TASK-501 đến TASK-504 và xuất file Word `Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx` gồm 5 giai đoạn phát triển logic từ lõi dữ liệu đến giao diện.

---

### 2. Yêu cầu lập kế hoạch chuyên sâu (`/plan`) kết hợp kiểm soát nghiêm ngặt quyền Git
- **Prompt nguyên văn của sinh viên (Giai đoạn 1 - Kiến trúc & SQLite)**:
  > `/plan lên kế hoạch thực hiện giai đoạn 1 của M4 dựa vào file docx (Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx và app-StudyMate-AI.docx);`
  > 
  > `CHỈNH SỬA TRONG BẢN KẾ HOẠCH [plan_m4_stage1.md] NHỮNG YÊU CẦU SAU: TRONG BẢN KẾ HOẠCH CHỈ LÊN KẾ HOẠCH CHO GIAI ĐOẠN 1 THÔI; VỀ PHẦN QUẢN LÝ CODE TRÊN GIT THÌ YÊU CẦU LÀ KHÔNG TỰ Ý TẠO RẼ NHÁNH MỚI, KHÔNG TỰ Ý COMMIT VÀ PUSH CODE LÊN TRÊN GITHUB`
- **Prompt nguyên văn của sinh viên (Giai đoạn 3 - Thuật toán SM-2)**:
  > `/plan lên kế hoạch thực hiện giai đoạn 3 của M4 dựa vào file docx (Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx và app-StudyMate-AI.docx) kết hợp với các yêu cầu chuẩn của file Chủ đề project Flutter và Rubric cuối kỳ.pdf; YÊU CẦU BỔ SUNG: VỀ PHẦN QUẢN LÝ CODE TRÊN GIT THÌ YÊU CẦU LÀ KHÔNG TỰ Ý TẠO RẼ NHÁNH MỚI, KHÔNG TỰ Ý COMMIT VÀ PUSH CODE LÊN TRÊN GITHUB`
- **Prompt nguyên văn của sinh viên (Giai đoạn 4 - Quiz Engine & Chấm điểm)**:
  > `/plan lên kế hoạch thực hiện giai đoạn 4 của M4 dựa vào file docx (Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx và app-StudyMate-AI.docx) kết hợp với các yêu cầu chuẩn của file Chủ đề project Flutter và Rubric cuối kỳ.pdf; YÊU CẦU BỔ SUNG: VỀ PHẦN QUẢN LÝ CODE TRÊN GIT THÌ YÊU CẦU LÀ KHÔNG TỰ Ý TẠO RẼ NHÁNH MỚI, KHÔNG TỰ Ý COMMIT VÀ PUSH CODE LÊN TRÊN GITHUB`
- **Prompt nguyên văn của sinh viên (Giai đoạn 5 - Flashcards & UI lật thẻ 3D)**:
  > `/plan lên kế hoạch thực hiện giai đoạn 5 của M4 dựa vào file docx (Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx và app-StudyMate-AI.docx) kết hợp với các yêu cầu chuẩn của file Chủ đề project Flutter và Rubric cuối kỳ.pdf; YÊU CẦU BỔ SUNG: VỀ PHẦN QUẢN LÝ CODE TRÊN GIT THÌ YÊU CẦU LÀ KHÔNG TỰ Ý TẠO RẼ NHÁNH MỚI, KHÔNG TỰ Ý COMMIT VÀ PUSH CODE LÊN TRÊN GITHUB`
- **Phản hồi và đóng góp của AI**:
  - AI không viết mã bừa bãi mà tạo tài liệu Artifact kế hoạch kỹ thuật (`plan_m4_stage1.md`, `stage3.md`, `stage4.md`, `stage5.md`) với đầy đủ code snippet, diff, phương án kiểm thử để sinh viên duyệt trước (`RequestFeedback: true`).
  - Tuyệt đối tuân thủ nguyên tắc không can thiệp vào Git, bảo đảm an toàn dữ liệu cho repository của cả nhóm.

---

### 3. Phản biện kiến trúc và phân định ranh giới trách nhiệm giữa các module (M4 vs M5)
- **Prompt nguyên văn của sinh viên**:
  > `nội dung trong phần kế hoạch của giai đoạn 2 thì tôi có thấy phần gemini api thì phần này tôi tưởng là phần công việc của M5 mà`
  > 
  > `API DTOs; vậy là phần này là của M4 hay M5`
- **Phản hồi và đóng góp của AI**:
  - AI tiếp thu phản biện của sinh viên, phân định rõ:
    - Module 5 (M5): Chịu trách nhiệm trực tiếp gọi API Gemini và parse JSON từ AI.
    - Module 4 (M4): Chỉ định nghĩa các cấu trúc truyền nhận `QuizDTO` / `FlashcardDTO` làm giao ước dữ liệu (Interface Contract), sau đó lưu vào SQLite để phục vụ thi trắc nghiệm và ôn tập ngắt quãng cục bộ.
  - Sinh viên điều chỉnh kế hoạch để M4 không lấn sân sang nghiệp vụ M5, tránh trùng lặp mã nguồn trong nhóm.

---

### 4. Kiểm thử chất lượng và rà soát lỗi tĩnh (`dart analyze`)
- **Prompt nguyên văn của sinh viên**:
  > `đang phân tích flutter analyze thì thấy lỗi nào; fix lỗi cho tôi`
  > 
  > `thế khi xong giai đoạn 2 với phần của tôi có thể thao tác gì để biết phần công việc code giai đoạn 2 của tôi đang hoạt động đúng`
- **Phản hồi và đóng góp của AI**:
  - AI tiến hành quét toàn bộ codebase bằng `dart analyze`, phát hiện các tham số sai lệch ở widget dùng chung (`SectionHeader`, `MasteryBadge`) và sửa triệt để.
  - Hướng dẫn sinh viên kiểm chứng chất lượng mã nguồn bằng 16 ca kiểm thử tự động độc lập qua lệnh `flutter test` mà không cần đợi backend hay màn hình khác hoàn thiện.

---

### 5. Hướng dẫn quản trị phiên bản Git Commit theo chuẩn quy ước tài liệu dự án
- **Prompt nguyên văn của sinh viên**:
  > `bây giờ tôi muốn đẩy code mới lên trên nhánh hiện tại (M4_Thien) ; bạn hãy gợi ý cho tôi dùng git commit như thế nào dựa vào tài liệu app-StudyMate-AI.docx; lưu ý là tôi không muốn đẩy các file sau lên trên git: ảnh minh họa giao diện app.docx; app-StudyMate-AI.docx; Chủ đề project Flutter và Rubric cuối kỳ.pdf; Ke-Hoach-Cong-Viec-M4-StudyMate-AI.docx`
  > 
  > `@[Quote] phần nội dung viết tiếng việt có dấu giúp tôi với`
  > 
  > `tôi muốn add cả file settings.json để push code lên nhánh hiện tại`
- **Phản hồi và đóng góp của AI**:
  - AI trích xuất cú pháp chuẩn Conventional Commits trong mục 5.1 của `app-StudyMate-AI.docx`: `<type>(<scope>): [<Mã_Task>] <Mô tả>`.
  - Cung cấp câu lệnh `git add` loại trừ hoàn toàn các tài liệu `.docx` và `.pdf`.
  - Soạn thông điệp commit bằng tiếng Việt có dấu chuẩn chỉnh:
    `git commit -m "feat(flashcards): [TASK-504] hoàn thiện bộ thẻ SCR-09, màn hình lật thẻ SM-2 SCR-10 và repository"`
  - Hướng dẫn sinh viên tự tay thực hiện đẩy mã nguồn lên nhánh `M4_Thien` an toàn.

---

### 6. Xây dựng tài liệu báo cáo sử dụng AI theo yêu cầu Rubric cuối kỳ
- **Prompt nguyên văn của sinh viên**:
  > `trong phần dùng trợ lý AI của file Chủ đề project Flutter và Rubric cuối kỳ.pdf thì có yêu cầu là phải cho biết bản thân mình dùng AI ở phần nào; hỗ trợ đoạn nào; công nghệ hỗ trợ là gì (hiểu đơn giản là làm việc với AI ra làm sao trong dự án này); /plan giờ bạn hãy giúp tôi lập kế hoạch để làm nội dung phần này vào một file .md nhé; lưu ý là tôi là người thực hiện công việc của M4`
  > 
  > `chỉnh sửa trong bản kế hoạch là đổi tên file thành M4_Thien_ai_report.md và đổi vị trí thư mục thành D:\StudyMate-AI\M4_Thien_ai_report.md; YÊU CẦU BỔ SUNG: VỀ PHẦN QUẢN LÝ CODE TRÊN GIT THÌ YÊU CẦU LÀ KHÔNG TỰ Ý TẠO RẼ NHÁNH MỚI, KHÔNG TỰ Ý COMMIT VÀ PUSH CODE LÊN TRÊN GITHUB`
- **Phản hồi và đóng góp của AI**:
  - AI lập tức lập kế hoạch chi tiết, cập nhật đúng tên file `M4_Thien_ai_report.md` tại thư mục gốc, bảo đảm nguyên tắc không tự ý commit/push code lên Git, và tổng hợp đầy đủ các tiêu chí chấm điểm của giảng viên.

---

## V. MA TRẬN GIẢI THÍCH MÃ NGUỒN (CODE COMPREHENSION GUIDE)

*Phần này tổng hợp các câu hỏi chất vấn trọng tâm của hội đồng chấm đồ án và lời giải thích chi tiết, chứng minh sinh viên hoàn toàn làm chủ mã nguồn:*

### 1. Thuật toán `Sm2Calculator` hoạt động ra sao?
- **Câu hỏi**: *Hãy giải thích cơ chế tăng giảm khoảng thời gian ôn tập (Interval) của thuật toán SM-2 trong mã nguồn của bạn?*
- **Trả lời**:
  - Khi người dùng đánh giá câu hỏi đạt (`quality >= 3`):
    - Lần lặp đầu tiên (`repetitions = 0`): `interval = 1` ngày.
    - Lần lặp thứ hai (`repetitions = 1`): `interval = 6` ngày.
    - Các lần lặp tiếp theo ($n \ge 2$): `interval = round(interval_cũ * easeFactor)`.
  - Hệ số dễ `easeFactor` (mặc định ban đầu 2.5) sẽ tăng nếu chất lượng nhớ cao ($q = 5$) và giảm nếu nhớ khó ($q = 3$). Giới hạn sàn luôn là 1.3 để không xảy ra trường hợp thẻ bị kẹt vô hạn:
    $$EF' = EF + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02))$$
  - Nếu người dùng đánh giá quên (`quality < 3`): `repetitions` bị reset về 0 và `interval` lập tức quay về 1 ngày để yêu cầu ôn lại vào ngày mai.

### 2. Vì sao trong màn hình Flashcard Review lại dùng `Matrix4..setEntry(3, 2, 0.001)`?
- **Câu hỏi**: *Dòng mã `setEntry(3, 2, 0.001)` có vai trò gì trong hiệu ứng lật thẻ?*
- **Trả lời**:
  - Trong ma trận chuyển đổi 4x4 (`Matrix4`) của đồ họa máy tính, phần tử hàng 3 cột 2 đại diện cho thành phần phối cảnh trục Z (Perspective).
  - Giá trị `0.001` tạo ra cảm giác độ sâu thực tế trong không gian 3D khi vật thể xoay quanh trục Y: cạnh gần mắt người nhìn sẽ phình to hơn và cạnh xa sẽ thu nhỏ lại. Nếu không có giá trị này, thẻ sẽ chỉ co dãn 2D trông rất cứng nhắc.

### 3. Mô hình MVVM được tổ chức thế nào trong Module Quiz?
- **Câu hỏi**: *Trách nhiệm giữa `QuizRepository`, `QuizViewModel` và `ActiveQuizScreen` được phân chia như thế nào?*
- **Trả lời**:
  - `QuizRepository`: Chỉ đảm nhận việc truy vấn và lưu trữ dữ liệu với SQLite (lấy câu hỏi theo topic/deck, lưu `QuizAttempt`, lưu `AttemptAnswer`).
  - `QuizViewModel` (kế thừa `ChangeNotifier`): Nắm giữ trạng thái nghiệp vụ (câu hỏi hiện tại, danh sách đáp án chọn, đồng hồ đếm ngược `timeRemaining`, logic chấm điểm). Khi có thay đổi, gọi `notifyListeners()`.
  - `ActiveQuizScreen`: Thuần túy là tầng giao diện (View), lắng nghe `QuizViewModel` qua `Consumer` hoặc `ListenableBuilder` để cập nhật UI, không chứa code truy vấn cơ sở dữ liệu.

---

## VI. MINH CHỨNG KIỂM THỬ THỰC TẾ TRÊN MÁY (EVIDENCE OF TESTING)

Toàn bộ mã nguồn Module 4 đã được biên dịch và kiểm thử thành công 100% trước khi nộp:

### 1. Kết quả kiểm thử tự động (`flutter test`)
Chạy toàn bộ 4 file kiểm thử đơn vị với 16 test cases:
```
00:03 +16: All tests passed!
```
- `test/sm2_calculator_test.dart`: 6/6 test cases passed (Bao phủ đầy đủ các mức đánh giá SM-2 từ 0 đến 5).
- `test/m4_models_test.dart`: 4/4 test cases passed (Kiểm tra serialization toMap/fromMap cho QuizAttempt, AttemptAnswer, Flashcard, QuizDTO).
- `test/quiz_grading_test.dart`: 3/3 test cases passed (Kiểm thử chấm điểm đơn, nhiều đáp án, điền từ chuẩn hóa).
- `test/flashcard_flow_test.dart`: 3/3 test cases passed (Kiểm thử dòng cập nhật thẻ và lưu đánh giá SM-2).

### 2. Kết quả phân tích cú pháp tĩnh (`dart analyze`)
```
Analyzing mobile...
No issues found!
```
- Không có lỗi biên dịch (0 errors).
- Không có cảnh báo linter (0 warnings).

---

## VII. ĐOẠN TÓM TẮT DỰ THẢO CHO FILE `README.md` CHUNG

Đoạn văn bản dưới đây được soạn thảo sẵn để tích hợp vào mục **"Dùng AI"** trong file `README.md` chính của repository theo yêu cầu của Rubric:

```markdown
## Dùng Trợ Lý AI (AI Assistance)

Trong dự án StudyMate-AI, trợ lý AI (Google Antigravity / Gemini) được ứng dụng có trách nhiệm, tuân thủ nguyên tắc minh bạch và kiểm thử nghiêm ngặt:
- **Công cụ**: Google Antigravity (Gemini 2.5 Coding Assistant).
- **Phạm vi hỗ trợ Milestone 4 (Quiz & Flashcards - Phụ trách: Phạm Khánh Thiện)**:
  - Hỗ trợ xây dựng thuật toán SuperMemo SM-2 (`Sm2Calculator`) và logic chấm điểm trắc nghiệm.
  - Hỗ trợ boilerplate mã nguồn mô hình MVVM (`QuizViewModel`, `FlashcardViewModel`) và SQLite Repositories.
  - Thiết kế hiệu ứng xoay lật 3D flashcard (`Transform`, `Matrix4`).
  - Soạn thảo 16 test cases kiểm thử tự động đảm bảo độ bao phủ 100% logic trọng yếu.
- **Báo cáo chi tiết của M4**: Xem file [M4_Thien_ai_report.md](M4_Thien_ai_report.md).
- **Cam kết**: 100% mã nguồn được sinh viên kiểm tra, chạy thử thực tế (`flutter test` đạt 16/16) và hiểu rõ nguyên lý hoạt động để bảo vệ trước hội đồng.
```

---
*Tài liệu được khởi tạo và lưu trữ tại thư mục gốc dự án: `D:\StudyMate-AI\M4_Thien_ai_report.md`.*
