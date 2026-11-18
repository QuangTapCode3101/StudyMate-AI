const geminiService = require('../services/gemini.service');

const isMockEnabled = (req) =>
  process.env.USE_MOCK_AI === 'true' || req.headers['x-mock-mode'] === 'true';

/**
 * 1. POST /api/v1/documents/extract-topics (M2 - SCR-04)
 */
exports.extractTopics = async (req, res, next) => {
  try {
    const { subjectName, programmingLanguage, documentTitle, chunks } = req.body;

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
          topics: [
            {
              name: 'ChangeNotifier',
              keywords: ['ChangeNotifier', 'notifyListeners()', 'extends'],
              chunkIndices: [chunks[0].chunkIndex || 1],
            },
            {
              name: 'Provider & Consumer',
              keywords: ['Provider', 'Consumer', 'context.watch()', 'context.read()'],
              chunkIndices: [chunks[0].chunkIndex || 1],
            },
            {
              name: 'Widget Rebuild Lifecycle',
              keywords: ['build()', 'StatefulWidget', 'rebuild'],
              chunkIndices: [chunks[chunks.length - 1].chunkIndex || 1],
            },
          ],
        },
      });
    }

    const result = await geminiService.extractTopicsFromChunks({
      subjectName,
      programmingLanguage,
      documentTitle,
      chunks,
    });

    return res.status(200).json({
      success: true,
      quota: req.quotaInfo,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 2. POST /api/v1/tutor/stream (M3 - SCR-05)
 */
exports.streamTutorResponse = async (req, res, next) => {
  // Thiết lập Header SSE
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  try {
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
          res.write(`data: ${JSON.stringify({ type: 'chunk', text: mockStreamChunks[index] })}\n\n`);
          index++;
        } else {
          clearInterval(intervalId);
          res.write(
            `data: ${JSON.stringify({
              type: 'done',
              citations: ['Trang 12'],
              quota: req.quotaInfo,
            })}\n\n`
          );
          res.end();
        }
      }, 200);

      req.on('close', () => clearInterval(intervalId));
      return;
    }

    const { subjectName, programmingLanguage, topicName, actionMode, userPrompt, sourceChunks, chatHistory } = req.body;

    const { citations } = await geminiService.streamTutor({
      subjectName,
      programmingLanguage,
      topicName,
      actionMode,
      userPrompt,
      sourceChunks,
      chatHistory,
      onChunk: (text) => {
        if (!res.writableEnded) {
          res.write(`data: ${JSON.stringify({ type: 'chunk', text })}\n\n`);
        }
      },
    });

    if (!res.writableEnded) {
      res.write(
        `data: ${JSON.stringify({
          type: 'done',
          citations,
          quota: req.quotaInfo,
        })}\n\n`
      );
      res.end();
    }
  } catch (err) {
    console.error('[SSE Stream Error]:', err);
    if (!res.writableEnded) {
      res.write(`data: ${JSON.stringify({ type: 'error', message: err.message || 'Lỗi luồng AI Tutor' })}\n\n`);
      res.end();
    }
  }
};

/**
 * 3. POST /api/v1/quiz/generate (M4 - SCR-06 & SCR-07)
 */
exports.generateTechnicalQuiz = async (req, res, next) => {
  try {
    const { programmingLanguage, difficulty, questionCount, questionTypes, topics } = req.body;

    if (!topics || !Array.isArray(topics) || topics.length === 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Cần chọn ít nhất 1 chủ đề để tạo đề Quiz.' },
      });
    }

    const defaultTopicId = topics[0].topicId || 1;

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
                'Hàm onPressed là callback sự kiện, không phải hàm build. Gọi context.watch() ở đây sẽ gây lỗi runtime; phải dùng context.read<CartModel>().',
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

    const result = await geminiService.generateQuiz({
      programmingLanguage,
      difficulty,
      questionCount,
      questionTypes,
      topics,
    });

    return res.status(200).json({
      success: true,
      quota: req.quotaInfo,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 4. POST /api/v1/quiz/generate-mini (M3 - MDL-02: Đủ 3 câu trắc nghiệm nhanh)
 */
exports.generateMiniQuiz = async (req, res, next) => {
  try {
    const { programmingLanguage, topicId, tutorAnswer, content } = req.body;
    const referenceText = tutorAnswer || content;

    if (isMockEnabled(req)) {
      return res.status(200).json({
        success: true,
        quota: req.quotaInfo,
        data: {
          questions: [
            {
              topicId: topicId || 1,
              questionType: 'CONCEPT',
              questionText: 'Khi chỉ muốn gọi phương thức trong onPressed mà không cần rebuild Widget, ta dùng hàm nào?',
              codeSnippet: 'context.____<Counter>().increment();',
              options: ['context.watch()', 'context.read()', 'context.select()', 'Consumer'],
              correctIndex: 1,
              explanation: 'context.read<T>() chỉ đọc đối tượng từ Provider 1 lần mà không đăng ký lắng nghe thay đổi.',
            },
            {
              topicId: topicId || 1,
              questionType: 'CONCEPT',
              questionText: 'Hàm nào dưới đây sẽ đăng ký lắng nghe thay đổi và tự động gọi lại build() khi state cập nhật?',
              codeSnippet: null,
              options: ['context.read<T>()', 'context.watch<T>()', 'Provider.of(context, listen: false)', 'Navigator.of(context)'],
              correctIndex: 1,
              explanation: 'context.watch<T>() tương đương Provider.of<T>(context, listen: true), dùng trong hàm build().',
            },
            {
              topicId: topicId || 1,
              questionType: 'PREDICT_OUTPUT',
              questionText: 'Điều gì xảy ra nếu gọi context.watch<Counter>() bên trong hàm initState()?',
              codeSnippet: '1  @override\n2  void initState() {\n3    super.initState();\n4    final c = context.watch<Counter>();\n5  }',
              options: [
                'Chạy bình thường và cập nhật UI',
                'Ném ngoại lệ ProviderException vì gọi ngoài hàm build',
                'Trả về giá trị null',
                'Tự động chuyển thành context.read()',
              ],
              correctIndex: 1,
              explanation: 'context.watch() chỉ được phép gọi bên trong phương thức build() của Widget.',
            },
          ],
        },
      });
    }

    if (!referenceText) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Thiếu nội dung câu trả lời AI Tutor (tutorAnswer) để sinh Mini-Quiz.' },
      });
    }

    const result = await geminiService.generateMiniQuizFromTutor({
      programmingLanguage,
      topicId,
      tutorAnswer: referenceText,
    });

    return res.status(200).json({
      success: true,
      quota: req.quotaInfo,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};