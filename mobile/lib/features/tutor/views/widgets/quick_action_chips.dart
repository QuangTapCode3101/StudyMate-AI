import 'package:flutter/material.dart';

import '../../models/tutor_models.dart';
import '../tutor_style.dart';

/// Hàng 5 nút Quick Action cuộn ngang (Giải thích cơ bản, Cơ chế hoạt động,
/// So sánh khái niệm, Giải thích code, Lỗi thường gặp).
class QuickActionChips extends StatelessWidget {
  const QuickActionChips({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final TutorActionMode? selected;
  final bool enabled;
  final ValueChanged<TutorActionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: TutorActionMode.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = TutorActionMode.values[index];
          return _ActionChip(
            label: mode.label,
            isSelected: mode == selected,
            enabled: enabled,
            onTap: () => onSelected(mode),
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isSelected ? TutorStyle.primary : TutorStyle.surface;
    final Color foreground = isSelected ? Colors.white : TutorStyle.textDark;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? TutorStyle.primary : TutorStyle.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
