import 'package:flutter/material.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';
import 'package:unite_india_app/features/auth/phone_auth_page.dart';
import 'package:unite_india_app/features/host_onboarding/host_onboarding_page.dart';

class ApnaasaaLandingPage extends StatelessWidget {
  const ApnaasaaLandingPage({
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6B6B),
                            Color(0xFFFFD93D),
                            Color(0xFF6BCB77),
                            Color(0xFF4D96FF),
                            Color(0xFF9D4EDD),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.home_rounded,
                              color: Colors.black, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'ApnaaSaa Stays',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trusted stays for LGBTQIA+ in India',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Where are you in this journey?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ApnaaSaa Stays connects queer and ally travellers with hosts who offer safer, affirming homes across India.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryChoiceButton(
                            label: 'I want to stay',
                            icon: Icons.luggage_rounded,
                            onTap: () => _openPhoneAuth(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PrimaryChoiceButton(
                            label: 'I want to host',
                            icon: Icons.key_rounded,
                            onTap: () => _openPhoneAuth(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                        color: Colors.white.withOpacity(0.02),
                      ),
                      child: const Text(
                        'For this pilot, you can also explore the host journey in preview mode without SMS. '
                        'Verification will be required before any real bookings.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _enterPreviewHostFlow(context),
                      child: const Text(
                        'Preview host setup without SMS',
                        style: TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPhoneAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            PhoneAuthPage(authRepository: authRepository),
      ),
    );
  }

  void _enterPreviewHostFlow(BuildContext context) {
    final previewUser = UniteUser(
      id: 'preview-web-user',
      phoneNumber: '',
      isHost: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HostOnboardingPage(
          currentUser: previewUser,
          authRepository: authRepository,
          hostRepository: hostRepository,
          trustRepository: trustRepository,
        ),
      ),
    );
  }
}

class _PrimaryChoiceButton extends StatelessWidget {
  const _PrimaryChoiceButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
                      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

