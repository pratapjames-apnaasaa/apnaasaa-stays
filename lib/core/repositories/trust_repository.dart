import 'package:unite_india_app/core/domain/verification_status.dart';

abstract class TrustRepository {
  Future<TrustProfile> getTrustProfile(String userId);

  Future<void> updateTrustProfile(TrustProfile profile);
}

