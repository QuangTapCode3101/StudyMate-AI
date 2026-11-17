import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/code_snippet_box.dart';
import '../../utils/markdown_segmenter.dart';
import '../tutor_style.dart';

/// Hiển thị câu trả lời Markdown của AI: văn bản bằng flutter_markdown,
/// còn khối code (```) luôn dùng CodeSnippetBox dùng chung của M1.
class MarkdownCodeView extends StatelessWidget {
  const MarkdownCodeView({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final segments = MarkdownSegmenter.split(data);
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: TutorStyle.textDark,
      ),
      listBullet: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: TutorStyle.textDark,
      ),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: TutorStyle.primary,
        backgroundColor: TutorStyle.inlineCodeBackground,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final segment in segments)
          if (segment.isCode)
            CodeSnippetBox(
              code: segment.content,
              language: segment.language ?? 'dart',
            )
          else
            MarkdownBody(data: segment.content, styleSheet: styleSheet),
      ],
    );
  }
}
