import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studymate_ai/core/database/database_helper.dart';
import '../providers/auth_provider.dart';

class AuthGate extends StatefulWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  const AuthGate({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int? _preparedUserId;
  Future<void>? _prepareDbFuture;

  Future<void> _ensureDatabaseForUser(int userId) {
    if (_preparedUserId == userId &&
        DatabaseHelper.instance.currentUserId == userId &&
        DatabaseHelper.instance.isOpen) {
      return Future.value();
    }

    if (_preparedUserId != userId || _prepareDbFuture == null) {
      _preparedUserId = userId;
      _prepareDbFuture = DatabaseHelper.instance.setUserId(userId);
    }

    return _prepareDbFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.initializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = auth.user;
        if (!auth.isAuthenticated || user == null) {
          _preparedUserId = null;
          _prepareDbFuture = null;
          return widget.unauthenticatedChild;
        }

        return FutureBuilder<void>(
          future: _ensureDatabaseForUser(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Không thể khởi tạo cơ sở dữ liệu cho tài khoản.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _preparedUserId = null;
                              _prepareDbFuture = null;
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return KeyedSubtree(
              key: ValueKey<int>(user.id),
              child: widget.authenticatedChild,
            );
          },
        );
      },
    );
  }
}