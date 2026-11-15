const isMockEnabled = (req) =>
  process.env.USE_MOCK_AI === 'true' || req.headers['x-mock-mode'] === 'true';

/**
 * 1. API Bóc tách Chủ đề từ PDF/Notes/Code (Dành cho M2 - SCR-04)
 * POST /api/v1/documents/extract-topics
 */
exports.extractTopics = async (req, res, next) => {
  try {
    const { subjectName, documentTitle, chunks } = req.body;

    if (!chunks || !Array.isArray(chunks) || chunks.length === 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Danh sách chunks tài liệu không được để trống.' },
      });
    }

    if (isMockEnabled(req)) {
      return res.status(200).json({
        success: true,
        quota: req.quotaInfo,
        data: {
          summary: `Tài liệu ${documentTitle || 'môn học'} trình bày về quản lý trạng thái và vòng đời Widget trong ${subjectName || 'Flutter'}.`,
          topics: [
            {
              name: 'ChangeNotifier',
              keywords: ['ChangeNotifier', 'notifyListeners()', 'extends'],
              chunkIndices: [1],
            },
            {
              name: 'Provider & Consumer',
              keywords: ['Provider', 'Consumer', 'context.watch()', 'context.read()'],
              chunkIndices: [1],
            },
            {
              name: 'Widget Rebuild Lifecycle',
              keywords: ['build()', 'StatefulWidget', 'rebuild'],
              chunkIndices: [1],
            },
          ],
        },
      });
    }

    // TODO (TASK-202 - M5): Gọi geminiService.extractTopicsFromChunks(...) tại đây
    return res.status(501).json({
      success: false,
      error: { code: 'NOT_IMPLEMENTED', message: 'Chế độ Gemini thật đang được M5 tích hợp. Hãy bật USE_MOCK_AI=true.' },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 2. API AI Tutor Streaming SSE (Dành cho M3 - SCR-05)
 * POST /api/v1/tutor/stream
 */
exports.streamTutorResponse = async (req, res, next) => {
  try {
    // Thiết lập Header chuẩn Server-Sent Events (SSE)
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    if (isMockEnabled(req)) {
      const mockStreamChunks = [
        'Đây là sự khác biệt cốt lõi giữa `context.watch<T>()` và `context.read<T>()` trong Flutter:\n\n',
        '+ **`context.watch<T>()`**: Dùng bên trong hàm `build()` để lắng nghe sự thay đổi của dữ liệu và tự động rebuild UI.\n',
        '+ **`context.read<T>()`**: Chỉ lấy dữ liệu 1 lần duy nhất (dùng trong các hàm callback như `onPressed`) và không làm rebuild UI.\n\n',
        '```dart\n// Dùng watch trong hàm build\nfinal counter = context.watch<Counter>();\n\n// Dùng read trong sự kiện nút bấm\nElevatedButton(\n  onPressed: () {\n    context.read<Counter>().increment();\n  },\n  child: const Text("Tăng"),\n);\n```\n',
      ];

      let index = 0;
      const intervalId = setInterval(() => {
        if (index < mockStreamChunks.length) {
          const payload = JSON.stringify({ type: 'chunk', text: mockStreamChunks[index] });
          res.write(`data: ${payload}\n\n`);
          index++;
        } else {
          clearInterval(intervalId);
          const donePayload = JSON.stringify({
            type: 'done',
            citations: ['Trang 12'],
            quota: req.quotaInfo,
          });
          res.write(`data: ${donePayload}\n\n`);
          res.end();
        }
      }, 250); // Giả lập chữ chảy mỗi 250ms để M3 test UI Streaming mượt mà

      req.on('close', () => clearInterval(intervalId));
      return;
    }

    // TODO (TASK-203 - M5): Gọi geminiService.streamTutor(...) tại đây
    res.write(`data: ${JSON.stringify({ type: 'error', message: 'Gemini Stream chưa cấu hình' })}\n\n`);
    res.end();
  } catch (err) {
    next(err);
  }
};

/**
 * 3. API Tạo đề Technical Quiz (Dành cho M4 - SCR-06 & SCR-07)
 * POST /api/v1/quiz/generate
 */
exports.generateTechnicalQuiz = async (req, res, next) => {
  try {
    const { topics } = req.body;
    const defaultTopicId = topics && topics.length > 0 ? topics[0].topicId : 3;

    if (isMockEnabled(req)) {
      return res.status(200).json({
        success: true,
        quota: req.quotaInfo,
        data: {
          questions: [
            {
              topicId: defaultTopicId,
              questionType: 'SPOT_BUG',
              questionText: 'Đoạn code Flutter dưới đây có lỗi tiềm ẩn ở dòng nào?',
              codeSnippet:
                '1  class AddButton extends StatelessWidget {\n2    @override\n3    Widget build(BuildContext context) {\n4      return ElevatedButton(\n5        onPressed: () {\n6          context.watch<CartModel>().addItem();\n7        },\n8        child: const Text("Add to Cart"),\n9      );\n10   }\n11 }',
              options: [
                'Dòng 3: Thiếu từ khóa async ở hàm build',
                'Dòng 6: Không gọi context.watch bên trong hàm callback onPressed',
                'Dòng 8: Widget Text không được đặt const',
                'Đoạn code trên hoàn toàn đúng',
              ],
              correctIndex: 1,
              explanation:
                'Hàm onPressed là một callback sự kiện, không phải hàm build. Gọi context.watch() ở đây sẽ gây lỗi runtime; phải dùng context.read<CartModel>().',
            },
            {
              topicId: defaultTopicId,
              questionType: 'PREDICT_OUTPUT',
              questionText: 'Đoạn code Dart sau sẽ in ra kết quả gì trên màn hình console?',
              codeSnippet: '1  int x = 5;\n2  int y = x++;\n3  print("$x - $y");',
              options: ['5 - 5', '6 - 5', '6 - 6', '5 - 6'],
              correctIndex: 1,
              explanation:
                'Toán tử hậu tố x++ trả về giá trị ban đầu (5) gán vào biến y trước, sau đó mới tăng giá trị của x lên 6.',
            },
          ],
        },
      });
    }

    // TODO (TASK-204 - M5): Gọi geminiService.generateQuiz(...) tại đây
    return res.status(501).json({
      success: false,
      error: { code: 'NOT_IMPLEMENTED', message: 'Hãy bật USE_MOCK_AI=true để test.' },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 4. API Tạo nhanh Mini-Quiz 3 câu ngay dưới câu trả lời AI Tutor (Dành cho M3 - MDL-02)
 * POST /api/v1/quiz/generate-mini
 */
exports.generateMiniQuiz = async (req, res, next) => {
  try {
    if (isMockEnabled(req)) {
      return res.status(200).json({
        success: true,
        quota: req.quotaInfo,
        data: {
          questions: [
            {
              questionType: 'CONCEPT',
              questionText: 'Khi chỉ muốn gọi một phương thức trong onPressed mà không cần rebuild Widget, ta dùng hàm nào?',
              codeSnippet: 'context.____<Counter>().increment();',
              options: ['context.watch()', 'context.read()', 'context.select()', 'Consumer'],
              correctIndex: 1,
              explanation: 'context.read<T>() chỉ đọc đối tượng từ Provider 1 lần mà không đăng ký lắng nghe thay đổi.',
            },
          ],
        },
      });
    }

    return res.status(501).json({
      success: false,
      error: { code: 'NOT_IMPLEMENTED', message: 'Hãy bật USE_MOCK_AI=true để test.' },
    });
  } catch (err) {
    next(err);
  }
};