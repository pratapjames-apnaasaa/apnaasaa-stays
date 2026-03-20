import 'package:flutter/material.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/session/journey_intent.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({
    super.key,
    required this.authRepository,
    required this.journeyIntent,
  });

  final AuthRepository authRepository;
  final UserJourneyIntent journeyIntent;

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _isSendingCode = false;
  bool _isVerifying = false;

  String get _intentLine => switch (widget.journeyIntent) {
        UserJourneyIntent.guest => 'You are signing in to browse and book stays.',
        UserJourneyIntent.host => 'You are signing in to list your space as a host.',
      };

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_rounded,
                              color: Colors.black, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'ApnaaSaa Stays',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Trusted stays for LGBTQIA+ in India',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _intentLine,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _verificationId == null
                                  ? 'Let\'s secure your entry'
                                  : 'Check your SMS inbox',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _verificationId == null
                                  ? 'We start every journey by confirming it is really you. This helps keep ApnaaSaa Stays safer from impersonation and targeting.'
                                  : 'We have sent an OTP to your number. Enter it below to continue into your safer space.',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone number (India)',
                                hintText: '+91XXXXXXXXXX',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_isSendingCode && _verificationId == null,
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _verificationId == null
                                  ? const SizedBox.shrink()
                                  : TextField(
                                      key: const ValueKey('otp-field'),
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'OTP',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _verificationId == null
                                    ? (_isSendingCode ? null : _sendCode)
                                    : (_isVerifying ? null : _verifyCode),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: (_verificationId == null && _isSendingCode) ||
                                        (_verificationId != null && _isVerifying)
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _verificationId == null
                                            ? 'SEND OTP'
                                            : 'VERIFY & CONTINUE',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We never share your number publicly. It is used only for security and trust signals inside ApnaaSaa Stays.',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
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

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    await widget.authRepository.signInWithPhone(
      phoneNumber: phone,
      codeSent: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isSendingCode = false;
        });
      },
      onError: (Exception error) {
        setState(() {
          _isSendingCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send code: $error')),
        );
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP you received')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await widget.authRepository.confirmOtp(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isVerifying = false;
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not verify code: $error')),
      );
    }
  }
}
