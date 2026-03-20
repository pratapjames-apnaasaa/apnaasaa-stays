import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unite_india_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';
import 'package:unite_india_app/data/firebase/firebase_auth_repository.dart';
import 'package:unite_india_app/data/firebase/firebase_host_repository.dart';
import 'package:unite_india_app/data/firebase/firebase_trust_repository.dart';
import 'package:unite_india_app/features/shell/auth_gate.dart';
import 'package:unite_india_app/platform/load_google_maps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await loadGoogleMapsScript();

  final hostRepository = FirebaseHostRepository(FirebaseFirestore.instance);
  final authRepository = FirebaseAuthRepository(FirebaseAuth.instance);
  final trustRepository = FirebaseTrustRepository(FirebaseFirestore.instance);

  runApp(
    UniteIndiaApp(
      hostRepository: hostRepository,
      authRepository: authRepository,
      trustRepository: trustRepository,
    ),
  );
}

class UniteIndiaApp extends StatelessWidget {
  const UniteIndiaApp({
    super.key,
    required this.hostRepository,
    required this.authRepository,
    required this.trustRepository,
  });

  final FirebaseHostRepository hostRepository;
  final FirebaseAuthRepository authRepository;
  final TrustRepository trustRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApnaaSaa Stays',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(
        authRepository: authRepository,
        hostRepository: hostRepository,
        trustRepository: trustRepository,
      ),
    );
  }
}
