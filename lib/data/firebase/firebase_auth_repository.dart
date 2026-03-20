import 'package:firebase_auth/firebase_auth.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<UniteUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user == null) {
        return null;
      }
      return UniteUser(
        id: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        isHost: false,
      );
    });
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(Exception error) onError,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e);
      },
      codeSent: (String verificationId, int? _) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<void> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> signInAnonymously() async {
    await _firebaseAuth.signInAnonymously();
  }
}

