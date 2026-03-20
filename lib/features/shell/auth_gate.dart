import 'package:flutter/material.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';
import 'package:unite_india_app/features/landing/apnaasaa_landing_page.dart';
import 'package:unite_india_app/features/shell/authenticated_shell.dart';

/// Routes signed-out users to the landing page and signed-in users to the app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.hostRepository,
    required this.trustRepository,
  });

  final AuthRepository authRepository;
  final HostRepository hostRepository;
  final TrustRepository trustRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UniteUser?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load session: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return ApnaasaaLandingPage(
            authRepository: authRepository,
            hostRepository: hostRepository,
            trustRepository: trustRepository,
          );
        }
        return AuthenticatedShell(
          user: user,
          authRepository: authRepository,
          hostRepository: hostRepository,
          trustRepository: trustRepository,
        );
      },
    );
  }
}
