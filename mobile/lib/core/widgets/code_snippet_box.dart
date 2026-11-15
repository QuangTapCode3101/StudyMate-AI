import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart'; // Sử dụng theme tối có sẵn
import 'package:google_fonts/google_fonts.dart';

class CodeSnippetBox extends StatelessWidget {
  final String code;
  final String language;
  final bool showLineNumbers;

  const CodeSnippetBox({
    super.key,
    required this.code,
    this.language = 'dart',
    this.showLineNumbers = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép đoạn code!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Nền tối chuẩn mockup
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh tiêu đề và nút Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: const Row(
                    children: [
                      Icon(Icons.copy, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text('Sao chép', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Khung hiển thị code có cuộn ngang chống tràn màn hình
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: HighlightView(
                code,
                language: language,
                theme: darculaTheme,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}