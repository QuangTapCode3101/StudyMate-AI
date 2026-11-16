import 'package:flutter/material.dart';

class RateLimitBadge extends StatelessWidget {
  final int remaining;
  final int maxQuota;
  final bool isOnline;
  final VoidCallback? onTap;

  const RateLimitBadge({
    super.key,
    required this.remaining,
    this.maxQuota = 20,
    this.isOnline = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = remaining <= 3;
    final Color bgColor = !isOnline
        ? const Color(0xFFF1F5F9)
        : (isLow ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF));
    final Color textColor = !isOnline
        ? const Color(0xFF64748B)
        : (isLow ? const Color(0xFFEF4444) : const Color(0xFF2563EB));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.auto_awesome : Icons.cloud_off_outlined,
              size: 15,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? '$remaining/$maxQuota lượt AI' : 'Offline • $remaining/$maxQuota',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}