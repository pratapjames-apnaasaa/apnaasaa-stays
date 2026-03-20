/// Set from the landing page before opening phone auth; consumed when the
/// authenticated shell builds so we can open the right tab (guest vs host).
enum UserJourneyIntent {
  guest,
  host,
}

class PendingJourneyIntent {
  PendingJourneyIntent._();

  static UserJourneyIntent? _pending;

  static void set(UserJourneyIntent intent) {
    _pending = intent;
  }

  /// Returns and clears the pending intent (call once when entering the shell).
  static UserJourneyIntent? take() {
    final v = _pending;
    _pending = null;
    return v;
  }
}
