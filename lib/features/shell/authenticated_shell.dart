import 'package:flutter/material.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';
import 'package:unite_india_app/core/session/journey_intent.dart';
import 'package:unite_india_app/features/guest/guest_browse_page.dart';
import 'package:unite_india_app/features/host_onboarding/host_onboarding_page.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    super.key,
    required this.user,
    required this.authRepository,
    required this.hostRepository,
    required this.trustRepository,
  });

  final UniteUser user;
  final AuthRepository authRepository;
  final HostRepository hostRepository;
  final TrustRepository trustRepository;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final intent = PendingJourneyIntent.take();
    _index = intent == UserJourneyIntent.host ? 1 : 0;
    final openHostSetup = PendingHostSetup.take();
    if (openHostSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openHostOnboarding();
      });
    }
  }

  Future<void> _openHostOnboarding() async {
    final snapshot =
        await widget.hostRepository.getHostListingForUser(widget.user.id);

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HostOnboardingPage(
          currentUser: widget.user,
          authRepository: widget.authRepository,
          hostRepository: widget.hostRepository,
          trustRepository: widget.trustRepository,
          initialListing: snapshot,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ApnaaSaa Stays'),
        actions: [
          TextButton(
            onPressed: () => widget.authRepository.signOut(),
            child: const Text(
              'Sign out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          GuestBrowsePage(hostRepository: widget.hostRepository),
          _HostHomeTab(
            user: widget.user,
            hostRepository: widget.hostRepository,
            onStartOrContinue: () => _openHostOnboarding(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key),
            label: 'Host',
          ),
        ],
      ),
    );
  }
}

class _HostHomeTab extends StatelessWidget {
  const _HostHomeTab({
    required this.user,
    required this.hostRepository,
    required this.onStartOrContinue,
  });

  final UniteUser user;
  final HostRepository hostRepository;
  final Future<void> Function() onStartOrContinue;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: hostRepository.getHostListingForUser(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = snapshot.data;
        final status = listing?.listingStatus ?? 'none';
        final statusLabel = switch (status) {
          'published' => 'Published',
          'draft' => 'Draft saved',
          _ => 'No listing yet',
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Signed in as ${user.phoneNumber.isEmpty ? user.id : user.phoneNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(
                'Hosting',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your space for LGBTQIA+ travellers. You can save a draft and publish when ready.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your listing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(statusLabel),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (listing != null && listing.displayName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          listing.displayName!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onStartOrContinue,
                        icon: const Icon(Icons.edit_note),
                        label: Text(
                          listing == null
                              ? 'Start host setup'
                              : 'Continue / edit listing',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
