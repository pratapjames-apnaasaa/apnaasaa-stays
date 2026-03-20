import 'package:flutter/material.dart';
import 'package:unite_india_app/core/domain/guest_listing.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/features/guest/listing_detail_page.dart';

class GuestBrowsePage extends StatefulWidget {
  const GuestBrowsePage({
    super.key,
    required this.hostRepository,
  });

  final HostRepository hostRepository;

  @override
  State<GuestBrowsePage> createState() => _GuestBrowsePageState();
}

class _GuestBrowsePageState extends State<GuestBrowsePage> {
  late Future<List<GuestListingSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.hostRepository.listPublishedGuestListings();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.hostRepository.listPublishedGuestListings();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<GuestListingSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load listings: ${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            );
          }
          final items = snapshot.data ?? <GuestListingSummary>[];
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No published stays yet. When hosts publish to the pilot, they will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final g = items[i];
              final priceMin = g.minNightlyPriceInr;
              final priceMax = g.maxNightlyPriceInr;
              final priceLine = (priceMin != null || priceMax != null)
                  ? '₹${priceMin ?? '—'} – ${priceMax ?? '—'} / night'
                  : 'Price on request';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(g.displayName.isEmpty ? 'Stay' : g.displayName),
                  subtitle: Text(
                    '${g.locationLine}\n$priceLine',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => ListingDetailPage(
                          listingId: g.id,
                          hostRepository: widget.hostRepository,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
