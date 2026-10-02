import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../services/ground_service.dart';
import '../booking/booking_checkout_screen.dart';
import '../booking/checkout_args.dart';

/// Ground detail screen with 4 tabs: Overview, Calendar, Reviews, Location.
class GroundDetailScreen extends StatefulWidget {
  const GroundDetailScreen({super.key, required this.groundId});

  static const String route = '/grounds/detail';
  final String groundId;

  @override
  State<GroundDetailScreen> createState() => _GroundDetailScreenState();
}

class _GroundDetailScreenState extends State<GroundDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);
  Ground? _ground;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = context.read<GroundService>();
      final g = await service.getGround(widget.groundId);
      if (!mounted) return;
      setState(() {
        _ground = g;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Couldn\'t load ground';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(context),
      bottomNavigationBar: _ground == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${_ground!.priceWeekdayHourly}/hr',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('Weekday • ${_ground!.pitchType}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final ground = _ground!;
                          final hours = ground.slotDurationMinutes ~/ 60;
                          final amountPaise =
                              ground.priceWeekdayHourly * 100 * hours;
                          final platformFeePaise =
                              (amountPaise * AppConstants.platformFeePct).round();
                          Navigator.pushNamed(
                            context,
                            BookingCheckoutScreen.route,
                            arguments: CheckoutArgs(
                              ground: ground,
                              dateIso: _todayIso(),
                              slotStart: ground.openTime,
                              slotEnd: _addMinutes(
                                  ground.openTime,
                                  ground.slotDurationMinutes),
                              amountPaise: amountPaise,
                              platformFeePaise: platformFeePaise,
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_available_rounded, size: 18),
                        label: const Text('Book this ground'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final g = _ground!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(background: _heroCarousel(g)),
          actions: [
            IconButton(
                onPressed: () {/* share */},
                icon: const Icon(Icons.ios_share_rounded)),
            IconButton(
                onPressed: () {/* save */},
                icon: const Icon(Icons.bookmark_border_rounded)),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(g.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    if (g.verified)
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF0EA5E9), size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${g.city} • ${g.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB400), size: 18),
                    const SizedBox(width: 4),
                    Text(g.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (g.reviewCount > 0)
                      Text('  (${g.reviewCount} reviews)',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(_tab),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tab,
            children: [
              OverviewTab(ground: g),
              CalendarTab(ground: g),
              const ReviewsTab(),
              LocationTab(ground: g),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroCarousel(Ground g) {
    final urls = g.photos.isNotEmpty
        ? g.photos
        : (g.coverPhotoUrl.isNotEmpty ? [g.coverPhotoUrl] : <String>[]);
    if (urls.isEmpty) {
      return Container(
        color: AppTheme.surfaceSoft,
        child: const Center(
          child: Icon(Icons.sports_cricket_rounded,
              size: 80, color: AppTheme.textSecondary),
        ),
      );
    }
    return PageView.builder(
      itemCount: urls.length,
      itemBuilder: (_, i) => CachedNetworkImage(
        imageUrl: urls[i],
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppTheme.surfaceSoft),
        errorWidget: (_, __, ___) => Container(
          color: AppTheme.surfaceSoft,
          child: const Icon(Icons.sports_cricket_rounded,
              size: 80, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

String _todayIso() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

String _addMinutes(String hhmm, int minutes) {
  final parts = hhmm.split(':');
  final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabController);
  final TabController tabController;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Calendar'),
          Tab(text: 'Reviews'),
          Tab(text: 'Location'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController;
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.ground});
  final Ground ground;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (ground.amenities.isEmpty)
          Text('No amenities listed',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ground.amenities
                .map((a) => Chip(
                      avatar: const Icon(Icons.check_circle_outline,
                          size: 14, color: AppTheme.primary),
                      label: Text(a.replaceAll('_', ' ')),
                      backgroundColor: AppTheme.primaryContainer,
                    ))
                .toList(),
          ),
        const SizedBox(height: 20),
        Text('Pricing', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _priceLine(context, 'Weekday hourly',
                    '₹${ground.priceWeekdayHourly}'),
                const Divider(height: 24),
                _priceLine(context, 'Weekend hourly',
                    '₹${ground.priceWeekendHourly}'),
                if (ground.priceFullDay > 0) ...[
                  const Divider(height: 24),
                  _priceLine(context, 'Full day', '₹${ground.priceFullDay}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _metaRow('Opens', ground.openTime),
        _metaRow('Closes', ground.closeTime),
        _metaRow('Slot duration', '${ground.slotDurationMinutes} min'),
      ],
    );
  }

  Widget _priceLine(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key, required this.ground});
  final Ground ground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_rounded,
                size: 64, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text('Pick your slot',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap "Book this ground" below to choose date and time.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.reviews_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text('No reviews yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Reviews appear here after a booking is completed.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LocationTab extends StatelessWidget {
  const LocationTab({super.key, required this.ground});
  final Ground ground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.location_on_rounded, color: AppTheme.primary),
              title: Text(ground.address),
              subtitle: Text(ground.city),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {/* maps */},
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Get directions'),
          ),
        ],
      ),
    );
  }
}