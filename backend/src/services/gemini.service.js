const { GoogleGenAI, Type } = require('@google/genai');

// Đọc danh sách API Keys từ .env để xoay vòng (Key Rotation)
const apiKeys = (process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || '')
  .split(',')
  .map((k) => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;
const MODEL_NAME = process.env.GEMINI_MODEL;

function getNextClient() {
  if (apiKeys.length === 0) {
    throw new Error('Chưa cấu hình GEMINI_API_KEYS trong file .env');
  }
  const key = apiKeys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
  return new GoogleGenAI({ apiKey: key });
}

// Thử lại nếu lỗi 429 hoặc 503
async function executeWithKeyFallback(fn) {
  let lastError;
  const attempts = Math.max(1, apiKeys.length);
  for (let i = 0; i < attempts; i++) {
    try {
      const ai = getNextClient();
      return await fn(ai);
    } catch (err) {
      lastError = err;
      const status = err?.status || err?.code;
      // Nếu lỗi quá tải/hết quota trên key hiện tại -> thử key kế tiếp
      if (status === 429 || status === 503) {
        console.warn(`[Gemini Key Fallback] Key #${i + 1} gặp lỗi ${status}, đang chuyển key...`);
        continue;
      }
      throw err;
    }
  }
  throw lastError;
}

/**
 * TASK-202: Bóc tách chủ đề kiến thức CNTT với Structured Output (JSON Schema)
 */
exports.extractTopicsFromChunks = async ({ subjectName, programmingLanguage, documentTitle, chunks }) => {
  const formattedChunks = chunks
    .map((c) => `[chunkIndex: ${c.chunkIndex} | ${c.pageLabel}]\n${c.content}`)
    .join('\n\n---\n\n');

  const systemInstruction = `Bạn là chuyên gia phân tích tài liệu giảng dạy Công nghệ Thông tin.
Nhiệm vụ: Đọc các đoạn trích tài liệu của môn "${subjectName}" (ngôn ngữ: ${programmingLanguage}), bóc tách TOÀN BỘ các chủ đề kiến thức được nhắc đến trong tài liệu.

Quy tắc bắt buộc (Quan trọng):
1. KHÔNG ĐƯỢC GỘP CHỦ ĐỀ: Nếu tài liệu đã chia rõ các đề mục hoặc đánh số thứ tự (ví dụ: 01, 02, 03...), phải tách riêng từng đề mục thành một object độc lập. Bắt buộc trích xuất đủ 100% số lượng đề mục có trong tài liệu, không được bỏ sót hay tóm tắt gộp.
2. Tên chủ đề ("topic"): Ngắn gọn, chuẩn thuật ngữ chuyên ngành, giữ sát ý nghĩa của đề mục gốc.
3. Từ khóa ("keywords"): Mảng gồm 3-6 từ khóa, tên hàm, class hoặc khái niệm kỹ thuật đặc trưng nhất nằm trong phần nội dung của chủ đề đó.
4. Chỉ mục đoạn ("chunkIndices"): Mảng các số nguyên chunkIndex chứa nội dung chi tiết của chủ đề đó (bắt buộc khớp với chunkIndex đầu vào).

Định dạng đầu ra: Chỉ trả về duy nhất một mảng JSON hợp lệ (không kèm văn bản giải thích thừa hay markdown block nếu không cần thiết), cấu trúc mỗi phần tử:
{
  "topic": "string",
  "keywords": ["string"],
  "chunkIndices": [number]
}`;

  const responseSchema = {
    type: Type.OBJECT,
    properties: {
      topics: {
        type: Type.ARRAY,
        description: 'Danh sách các chủ đề kiến thức bóc tách được',
        items: {
          type: Type.OBJECT,
          properties: {
            name: { type: Type.STRING, description: 'Tên chủ đề kiến thức' },
            keywords: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: 'Danh sách từ khóa/tên hàm IT quan trọng',
            },
            chunkIndices: {
              type: Type.ARRAY,
              items: { type: Type.INTEGER },
              description: 'Danh sách chunkIndex liên quan tới chủ đề này',
            },
          },
          required: ['name', 'keywords', 'chunkIndices'],
        },
      },
    },
    required: ['topics'],
  };

  return executeWithKeyFallback(async (ai) => {
    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: `Tài liệu: ${documentTitle}\n\nNội dung chi tiết:\n${formattedChunks}`,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        responseSchema,
        temperature: 0.2,
      },
    });

    return JSON.parse(response.text);
  });
};

/**
 * TASK-203: Gia sư AI Streaming SSE + Ràng buộc nguồn trích dẫn
 */
const ACTION_PROMPTS = {
  BASIC: 'Giải thích khái niệm này một cách trực quan, dễ hiểu nhất cho sinh viên CNTT, kèm 1 ví dụ code ngắn gọn minh họa.',
  MECHANISM: 'Phân tích sâu cơ chế hoạt động bên dưới (under the hood), luồng thực thi hoặc quản lý bộ nhớ/vòng đời của khái niệm này.',
  COMPARE: 'Lập bảng so sánh chi tiết khái niệm này với các khái niệm dễ nhầm lẫn liên quan (về mục đích, hiệu năng, khi nào nên dùng).',
  EXPLAIN_CODE: 'Phân tích từng dòng/từng khối đoạn code trong tài liệu, giải thích vai trò của từng hàm và luồng dữ liệu.',
  PITFALLS: 'Liệt kê các lỗi phổ biến (bugs, anti-patterns, lỗi runtime/compile) sinh viên hay mắc phải khi dùng kiến thức này và cách khắc phục.',
};

exports.streamTutor = async ({
  subjectName,
  programmingLanguage,
  topicName,
  actionMode,
  userPrompt,
  sourceChunks = [],
  chatHistory = [],
  onChunk,
}) => {
  const modeInstruction = ACTION_PROMPTS[actionMode] || 'Trả lời câu hỏi của sinh viên một cách chính xác, sư phạm.';

  const contextText =
    sourceChunks.length > 0
      ? sourceChunks.map((c) => `--- Nguồn [${c.pageLabel}] ---\n${c.content}`).join('\n\n')
      : 'Không có đoạn tài liệu đính kèm.';

  const historyText =
    chatHistory.length > 0
      ? chatHistory
          .slice(-6)
          .map((m) => `${m.role === 'USER' ? 'Sinh viên' : 'AI Tutor'}: ${m.content}`)
          .join('\n')
      : '';

  const systemInstruction = `Bạn là StudyMate AI — Gia sư lập trình dành cho sinh viên CNTT (Môn: ${subjectName}, Ngôn ngữ: ${programmingLanguage}).
Chủ đề hiện tại: "${topicName}".
Chế độ hướng dẫn: ${modeInstruction}

QUY TẮC BẮT BUỘC:
1. Ưu tiên bám sát tài liệu học tập được cung cấp dưới đây. Nếu tài liệu không đề cập đủ, có thể bổ sung kiến thức chuẩn nhưng phải ghi chú rõ.
2. Định dạng bằng Markdown sạch đẹp; mọi đoạn mã nguồn phải đặt trong block \`\`\`${(programmingLanguage || 'dart').toLowerCase()}\n...\n\`\`\`.
3. Ở dòng CUỐI CÙNG của câu trả lời, bắt buộc xuất đúng một thẻ theo cú pháp:
4. Trả lời súc tích, đi thẳng vào trọng tâm.
[CITATIONS: Trang X, Trang Y] (liệt kê các nhãn pageLabel từ tài liệu mà bạn đã sử dụng; nếu không dùng nguồn nào thì ghi [CITATIONS: NONE]).`;

  const fullPrompt = `TÀI LIỆU THAM KHẢO:\n${contextText}\n\nLỊCH SỬ TRÒ CHUYỆN:\n${historyText}\n\nCÂU HỎI CỦA SINH VIÊN:\n${userPrompt || modeInstruction}`;

  const ai = getNextClient();
  const stream = await ai.models.generateContentStream({
    model: MODEL_NAME,
    contents: fullPrompt,
    config: {
      systemInstruction,
      temperature: 0.4,
    },
  });

  let fullText = '';
  for await (const chunk of stream) {
    const chunkText = chunk.text || '';
    if (chunkText) {
      fullText += chunkText;
      const cleanChunk = chunkText.replace(/\[CITATIONS:.*?\]/g, '');
      if (cleanChunk) {
        onChunk(cleanChunk);
      }
    }
  }

  const validLabels = new Set(sourceChunks.map((c) => c.pageLabel));
  const match = fullText.match(/\[CITATIONS:\s*(.*?)\]/i);
  let citations = [];

  if (match && match[1] && match[1].trim().toUpperCase() !== 'NONE') {
    citations = match[1]
      .split(',')
      .map((s) => s.trim())
      .filter((label) => validLabels.size === 0 || validLabels.has(label));
  }

  if (citations.length === 0 && sourceChunks.length > 0) {
    citations = [...new Set(sourceChunks.slice(0, 2).map((c) => c.pageLabel))];
  }

  return { citations };
};

/**
 * TASK-204: Sinh câu hỏi Technical Quiz & Mini-Quiz 3 câu với JSON Schema
 */
const quizResponseSchema = {
  type: Type.OBJECT,
  properties: {
    questions: {
      type: Type.ARRAY,
      items: {
        type: Type.OBJECT,
        properties: {
          topicId: { type: Type.INTEGER, description: 'ID của chủ đề tương ứng' },
          questionType: {
            type: Type.STRING,
            enum: ['CONCEPT', 'PREDICT_OUTPUT', 'SPOT_BUG'],
          },
          questionText: { type: Type.STRING, description: 'Nội dung câu hỏi tiếng Việt' },
          codeSnippet: {
            type: Type.STRING,
            nullable: true,
            description: 'Đoạn code <= 12 dòng, đánh số dòng 1, 2, 3... ở đầu mỗi dòng. Null nếu là câu lý thuyết thuần.',
          },
          options: {
            type: Type.ARRAY,
            items: { type: Type.STRING },
            description: 'Danh sách đúng 4 phương án trả lời A, B, C, D',
          },
          correctIndex: {
            type: Type.INTEGER,
            description: 'Chỉ số đáp án đúng từ 0 đến 3',
          },
          explanation: {
            type: Type.STRING,
            description: 'Giải thích kỹ thuật chi tiết vì sao đáp án này đúng và các đáp án khác sai',
          },
        },
        required: ['topicId', 'questionType', 'questionText', 'options', 'correctIndex', 'explanation'],
      },
    },
  },
  required: ['questions'],
};

exports.generateQuiz = async ({
  programmingLanguage = 'Dart',
  difficulty = 'MEDIUM',
  questionCount = 5,
  questionTypes = ['CONCEPT', 'PREDICT_OUTPUT', 'SPOT_BUG'],
  topics = [],
}) => {
  const topicsDesc = topics
    .map((t) => `- topicId: ${t.topicId} | Tên chủ đề: "${t.topicName}"\n  Nội dung tham khảo: ${t.referenceContent || 'Kiến thức chuẩn'}`)
    .join('\n');

  const systemInstruction = `Bạn là giảng viên ra đề thi trắc nghiệm kỹ thuật lập trình (${programmingLanguage}), độ khó: ${difficulty}.
Hãy tạo chính xác ${questionCount} câu hỏi thuộc các dạng: ${questionTypes.join(', ')}.

QUY TẮC NGHIÊM NGẶT:
1. Mỗi câu hỏi phải gán đúng "topicId" lấy từ danh sách chủ đề được cung cấp.
2. "options" phải có ĐÚNG 4 phần tử phân biệt rõ ràng; "correctIndex" nằm trong khoảng 0..3.
3. Với dạng "SPOT_BUG" và "PREDICT_OUTPUT":
   - Bắt buộc có "codeSnippet" hợp lệ bằng ngôn ngữ ${programmingLanguage}, độ dài KHÔNG QUÁ 12 dòng.
   - Đánh số dòng rõ ràng ở đầu mỗi dòng (VD: "1  void main() {\\n2    int x = 1;\\n3  }").
   - Lỗi trong SPOT_BUG phải là lỗi logic, runtime hoặc sai nguyên lý ngôn ngữ (không đố lỗi thiếu dấu chấm phẩy vặt vãnh).
4. "explanation" giải thích rõ ràng, ngắn gọn, đi thẳng vào bản chất kỹ thuật.`;

  return executeWithKeyFallback(async (ai) => {
    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: `Danh sách chủ đề cần ra đề:\n${topicsDesc}`,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        responseSchema: quizResponseSchema,
        temperature: 0.3,
      },
    });

    const parsed = JSON.parse(response.text);
    parsed.questions = (parsed.questions || []).map((q) => ({
      ...q,
      codeSnippet: q.codeSnippet || null,
      options: q.options.slice(0, 4),
      correctIndex: Math.min(3, Math.max(0, q.correctIndex)),
    }));
    return parsed;
  });
};

exports.generateMiniQuizFromTutor = async ({
  programmingLanguage = 'Dart',
  topicId = 1,
  topicName = 'Kiểm tra nhanh nội dung vừa học',
  userQuestion = '',
  tutorAnswer,
}) => {
  const safeTopicId = Number(topicId) || 1;
  const trimmedContext = String(tutorAnswer || '').slice(0, 3500);
  const trimmedUserQuestion = String(userQuestion || '').slice(0, 500);

  const systemInstruction = `Bạn là giảng viên ra đề kiểm tra nhanh (Mini-Quiz) dựa trực tiếp trên cuộc hội thoại vừa diễn ra giữa sinh viên và Gia sư AI về ngôn ngữ ${programmingLanguage}.
Hãy tạo chính xác 3 câu hỏi trắc nghiệm ngắn gọn, thực tế để kiểm tra xem sinh viên đã thực sự hiểu phần giải thích vừa rồi hay chưa.

QUY TẮC NGHIÊM NGẶT:
1. BÁM SÁT NGỮ CẢNH: Toàn bộ 3 câu hỏi phải xuất phát trực tiếp từ kiến thức, ví dụ, hoặc lỗi sai đã được đề cập trong phần trả lời của Gia sư AI. Tuyệt đối KHÔNG hỏi lan man sang các chủ đề ngoài nội dung vừa chat.
2. Mỗi câu hỏi phải gán "topicId": ${safeTopicId}.
3. Dạng câu hỏi: Ưu tiên "CONCEPT" (kiểm tra hiểu bản chất/khái niệm vừa giải thích). Chỉ dùng "PREDICT_OUTPUT" hoặc "SPOT_BUG" nếu trong phần giải thích của Gia sư AI có chứa đoạn code hoặc ví dụ lập trình cụ thể.
4. Với dạng "SPOT_BUG" và "PREDICT_OUTPUT":
   - Bắt buộc có "codeSnippet" hợp lệ bằng ngôn ngữ ${programmingLanguage}, độ dài KHÔNG QUÁ 12 dòng.
   - Đánh số dòng rõ ràng ở đầu mỗi dòng (VD: "1  void main() {\\n2    int x = 1;\\n3  }").
5. "options" phải có ĐÚNG 4 phần tử phân biệt rõ ràng; các phương án nhiễu phải hợp lý dựa trên những nhầm lẫn phổ biến liên quan đến nội dung vừa học.
6. "correctIndex" nằm trong khoảng 0..3.
7. "explanation" giải thích ngắn gọn (1-2 câu), nhắc lại đúng trọng tâm kiến thức trong câu trả lời của Gia sư AI.`;

  const chatContextPrompt = [
    `Chủ đề: "${topicName}" (topicId: ${safeTopicId})`,
    trimmedUserQuestion ? `Câu hỏi của sinh viên:\n"${trimmedUserQuestion}"` : null,
    `Nội dung giải thích của Gia sư AI:\n"""\n${trimmedContext}\n"""`,
  ]
    .filter(Boolean)
    .join('\n\n');

  return executeWithKeyFallback(async (ai) => {
    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: chatContextPrompt,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        responseSchema: quizResponseSchema,
        temperature: 0.25, // Giữ temperature thấp để AI bám chặt vào nội dung vừa chat, tránh bịa thêm kiến thức ngoài
      },
    });

    const parsed = JSON.parse(response.text);
    const questions = (parsed.questions || []).slice(0, 3).map((q) => ({
      ...q,
      topicId: safeTopicId,
      codeSnippet: q.codeSnippet || null,
      options: (q.options || []).slice(0, 4),
      correctIndex: Math.min(3, Math.max(0, Number(q.correctIndex) || 0)),
    }));

    return { questions };
  });
};