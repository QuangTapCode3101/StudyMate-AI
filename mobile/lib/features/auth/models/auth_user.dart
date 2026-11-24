class AuthUser {
  final int id;
  final String email;
  final String displayName;
  final String plan; // 'FREE' hoặc 'PREMIUM'
  final DateTime? premiumUntil;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.plan,
    this.premiumUntil,
  });

  /// Kiểm tra gói Premium còn hiệu lực (kể cả khi đang dùng Offline)
  bool get isPremium {
    if (plan.toUpperCase() != 'PREMIUM') return false;
    if (premiumUntil == null) return true;
    return premiumUntil!.isAfter(DateTime.now());
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      plan: (json['plan'] as String? ?? 'FREE').toUpperCase(),
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.tryParse(json['premiumUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'plan': plan,
      'premiumUntil': premiumUntil?.toIso8601String(),
    };
  }
}