import 'package:unite_india_app/core/domain/user.dart';

abstract class AuthRepository {
  Stream<UniteUser?> authStateChanges();

  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(Exception error) onError,
  });

  Future<void> confirmOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();

  /// Anonymous Firebase Auth (e.g. preview host flow without phone OTP).
  Future<void> signInAnonymously();
}

