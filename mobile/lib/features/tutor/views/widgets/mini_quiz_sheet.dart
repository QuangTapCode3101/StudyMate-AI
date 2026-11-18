import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/code_snippet_box.dart';
import '../../models/tutor_models.dart';
import '../tutor_style.dart';

/// MDL-02: Mini-Quiz 3 câu ngay dưới câu trả lời của AI Tutor.
/// Chọn đáp án là hiện ngay Đúng/Sai kèm giải thích tại chỗ.
/// Đóng popup vẫn giữ nguyên màn hình chat bên dưới.
class MiniQuizSheet extends StatefulWidget {
  const MiniQuizSheet({super.key, required this.loadQuestions});

  /// Gọi API /api/v1/quiz/generate-mini (qua TutorViewModel.generateMiniQuiz).
  final Future<List<MiniQuizQuestion>> Function() loadQuestions;

  @override
  State<MiniQuizSheet> createState() => _MiniQuizSheetState();
}

class _MiniQuizSheetState extends State<MiniQuizSheet> {
  List<MiniQuizQuestion> _questions = [];
  final Map<int, int> _answers = {}; // vị trí câu hỏi -> đáp án đã chọn
  int _current = 0;
  bool _isLoading = true;
  bool _isFinished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await widget.loadQuestions();
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = questions;
        _answers.clear();
        _current = 0;
        _isFinished = false;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Không tạo được câu hỏi kiểm tra. Vui lòng thử lại.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = message;
    });
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _load();
  }

  int get _correctCount {
    var count = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Flexible(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.help_outline, color: TutorStyle.primary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Kiểm tra nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TutorStyle.textDark,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'AI đang tạo câu hỏi...',
              style: TextStyle(color: TutorStyle.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: TutorStyle.danger),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TutorStyle.textDark),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _retry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_isFinished) {
      return _buildResult();
    }
    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final question = _questions[_current];
    final answered = _answers.containsKey(_current);
    final isLast = _current == _questions.length - 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: TutorStyle.border,
              color: TutorStyle.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Câu ${_current + 1}/${_questions.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TutorStyle.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: TutorStyle.textDark,
            ),
          ),
          if (question.codeSnippet != null)
            CodeSnippetBox(code: question.codeSnippet!),
          const SizedBox(height: 8),
          for (var i = 0; i < question.options.length; i++)
            _buildOption(question, i),
          if (answered) ...[
            _buildExplanation(question),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (isLast) {
                  setState(() => _isFinished = true);
                } else {
                  setState(() => _current++);
                }
              },
              child: Text(isLast ? 'Xem kết quả' : 'Câu tiếp theo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(MiniQuizQuestion question, int index) {
    final answered = _answers.containsKey(_current);
    final isCorrect = index == question.correctIndex;
    final isSelected = _answers[_current] == index;

    Color background = TutorStyle.surface;
    Color borderColor = TutorStyle.border;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered && isCorrect) {
      background = TutorStyle.successLight;
      borderColor = TutorStyle.success;
      trailingIcon = Icons.check_circle;
      trailingColor = TutorStyle.success;
    } else if (answered && isSelected) {
      background = TutorStyle.dangerLight;
      borderColor = TutorStyle.danger;
      trailingIcon = Icons.cancel;
      trailingColor = TutorStyle.danger;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: answered
              ? null
              : () => setState(() => _answers[_current] = index),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Text(
                  '${String.fromCharCode(65 + index)}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TutorStyle.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.options[index],
                    style: const TextStyle(
                      fontSize: 14,
                      color: TutorStyle.textDark,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: trailingColor, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(MiniQuizQuestion question) {
    final isCorrect = _answers[_current] == question.correctIndex;
    final Color color = isCorrect ? TutorStyle.success : TutorStyle.danger;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TutorStyle.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TutorStyle.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Chính xác!' : 'Chưa đúng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.explanation,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: TutorStyle.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final total = _questions.length;
    final correct = _correctCount;
    final isGood = correct * 2 >= total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.emoji_events_outlined : Icons.menu_book_outlined,
            size: 48,
            color: isGood ? TutorStyle.success : TutorStyle.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đúng $correct/$total câu',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TutorStyle.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isGood
                ? 'Tuyệt vời! Bạn đã nắm khá chắc phần này.'
                : 'Hãy đọc lại câu trả lời của AI rồi thử lại nhé.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: TutorStyle.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại cuộc trò chuyện'),
            ),
          ),
        ],
      ),
    );
  }
}
