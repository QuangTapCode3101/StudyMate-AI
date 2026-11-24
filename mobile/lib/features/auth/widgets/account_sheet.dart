import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AccountSheet extends StatelessWidget {
  final VoidCallback onRedeemTap;
  final VoidCallback onLogoutTap;

  const AccountSheet({
    super.key,
    required this.onRedeemTap,
    required this.onLogoutTap,
  });

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: auth.isPremium
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFDBEAFE),
                child: Text(
                  (user?.displayName.isNotEmpty ?? false)
                      ? user!.displayName.trim()[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: auth.isPremium
                        ? const Color(0xFFB45309)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Người dùng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: auth.isPremium
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  auth.isPremium ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: auth.isPremium
                        ? const Color(0xFFB45309)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          if (auth.isPremium && user?.premiumUntil != null) ...[
            const SizedBox(height: 10),
            Text(
              'Gói Premium có hiệu lực đến ${_formatDate(user!.premiumUntil!)}',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.confirmation_number_outlined,
              color: Color(0xFF2563EB),
            ),
            title: const Text(
              'Nhập mã kích hoạt Premium',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onRedeemTap,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onLogoutTap,
          ),
        ],
      ),
    );
  }
}