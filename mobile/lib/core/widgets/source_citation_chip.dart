import 'package:flutter/material.dart';

class SourceCitationChip extends StatelessWidget {
  final String documentTitle;
  final String pageLabel;
  final VoidCallback? onTap;

  const SourceCitationChip({
    super.key,
    required this.documentTitle,
    required this.pageLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = documentTitle.isNotEmpty
        ? '$documentTitle • $pageLabel'
        : pageLabel;

    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Nguồn: $displayLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}