import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unite_india_app/features/shell/auth_gate.dart';
import 'fakes/fake_repositories.dart';

void main() {
  testWidgets('AuthGate shows loading then landing when user is null',
      (tester) async {
    final auth = FakeAuthRepository(initialUser: null);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authRepository: auth,
          hostRepository: FakeHostRepository(),
          trustRepository: FakeTrustRepository(),
        ),
      ),
    );

    await tester.pump();
    expect(find.textContaining('ApnaaSaa'), findsWidgets);
    expect(find.textContaining('Where are you in this journey?'), findsOneWidget);
  });
}
