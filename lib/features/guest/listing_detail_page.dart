import 'package:flutter/material.dart';
import 'package:unite_india_app/core/domain/guest_listing.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';

class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    required this.hostRepository,
  });

  final String listingId;
  final HostRepository hostRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stay details'),
      ),
      body: FutureBuilder<GuestListingDetail?>(
        future: hostRepository.getPublishedListingForGuest(listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          final d = snapshot.data;
          if (d == null) {
            return const Center(
              child: Text('This listing is not available.'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  d.displayName.isEmpty ? 'Stay' : d.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  d.areaLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if ((d.city != null && d.city!.isNotEmpty) ||
                    (d.state != null && d.state!.isNotEmpty))
                  Text(
                    [
                      if (d.city != null && d.city!.isNotEmpty) d.city!,
                      if (d.state != null && d.state!.isNotEmpty) d.state!,
                    ].join(', '),
                  ),
                const Divider(height: 32),
                _Section(
                  title: 'Pricing',
                  child: Text(
                    '₹${d.minNightlyPriceInr ?? '—'} – ${d.maxNightlyPriceInr ?? '—'} / night',
                  ),
                ),
                if (d.longStayDiscountOffered == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Long-stay discount offered'),
                  ),
                if (d.cleaningFeeInr != null || d.extraGuestFeeInr != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (d.cleaningFeeInr != null)
                        'Cleaning: ₹${d.cleaningFeeInr}',
                      if (d.extraGuestFeeInr != null)
                        'Extra guest: ₹${d.extraGuestFeeInr}',
                    ].join(' · '),
                  ),
                ],
                if (d.otherChargesNote != null &&
                    d.otherChargesNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(d.otherChargesNote!),
                ],
                const Divider(height: 32),
                _Section(
                  title: 'Property',
                  child: Text(
                    [
                      if (d.propertyType != null) d.propertyType!,
                      if (d.maxGuests != null) 'Up to ${d.maxGuests} guests',
                      if (d.bedrooms != null) '${d.bedrooms} bed',
                      if (d.beds != null) '${d.beds} beds',
                      if (d.bathrooms != null) '${d.bathrooms} baths',
                    ].where((e) => e.isNotEmpty).join(' · '),
                  ),
                ),
                if (d.exactAddress != null && d.exactAddress!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _Section(
                    title: 'Address (shared after booking — pilot)',
                    child: Text(d.exactAddress!),
                  ),
                ],
                if (d.landmark != null && d.landmark!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Landmark: ${d.landmark}'),
                  ),
                const Divider(height: 32),
                _Section(
                  title: 'House rules (summary)',
                  child: Text(_rulesLine(d)),
                ),
                const Divider(height: 32),
                _Section(
                  title: 'Safety & comfort',
                  child: Text(_safetyLine(d)),
                ),
                if (d.safetyNotesForQueerGuests != null &&
                    d.safetyNotesForQueerGuests!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(d.safetyNotesForQueerGuests!),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Bookings are not enabled in this pilot build.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _rulesLine(GuestListingDetail d) {
    final parts = <String>[
      if (d.ruleNoLateEntryAfter9 == true) 'No entry/exit after 9 PM',
      if (d.ruleNoSmokingInside == true) 'No smoking inside',
      if (d.ruleNoCooking == true) 'No cooking',
      if (d.ruleNoOutsideGuests == true) 'No outside guests',
      if (d.ruleNoPets == true) 'No pets',
    ];
    if (d.otherHouseRules != null && d.otherHouseRules!.isNotEmpty) {
      parts.add(d.otherHouseRules!);
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  static String _safetyLine(GuestListingDetail d) {
    final parts = <String>[
      if (d.safetyOnlyQueerOrAllies == true) 'Queer/allied only',
      if (d.safetyNoOutingDiscretion == true) 'Discretion',
      if (d.safetyBuildingSecurity24x7 == true) '24×7 security',
      if (d.safetySeparateEntry == true) 'Separate entry',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
