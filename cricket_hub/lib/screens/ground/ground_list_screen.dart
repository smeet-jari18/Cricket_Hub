import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/geo.dart';
import '../../models/ground_model.dart';
import '../../services/ground_service.dart';
import 'ground_detail_screen.dart';
import 'widgets/ground_filter_sheet.dart';
import '../../l10n/generated/app_localizations.dart';

/// Marketplace ground listing (Phase 3).
/// Filter chip bar at top + sort + vertical list of GroundCards.
class GroundListScreen extends StatefulWidget {
  const GroundListScreen({super.key, this.city});

  static const String route = '/grounds';
  final String? city;

  @override
  State<GroundListScreen> createState() => _GroundListScreenState();
}

class _GroundListScreenState extends State<GroundListScreen> {
  late final GroundService _service = context.read<GroundService>();
  String _city = 'Ahmedabad';
  String? _pitchType;
  int? _maxPrice;
  Set<String> _amenities = {};
  String _sortBy = 'rating'; // 'rating' | 'price' | 'distance'
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _city = widget.city ?? 'Ahmedabad';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.find_a_ground)),
      body: Column(
        children: [
          _buildFilterBar(context),
          const SizedBox(height: 8),
          _buildChipRow(context),
          const Divider(height: 1),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: l10n.search_grounds_city_pitch,
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clear_search,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
              // Filtering is client-side: the list is already fetched for the
              // selected city, and a Firestore full-text search would need a
              // third-party index (Algolia/Typesense) — Phase 3.5.
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => _openFilterSheet(context),
            icon: const Icon(Icons.tune_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _cityDropdown(),
          const SizedBox(width: 8),
          if (_pitchType != null) ...[
            _activeChip(_pitchType!.toUpperCase(),
                () => setState(() => _pitchType = null)),
            const SizedBox(width: 8),
          ],
          if (_maxPrice != null) ...[
            _activeChip('≤ ₹$_maxPrice/hr',
                () => setState(() => _maxPrice = null)),
            const SizedBox(width: 8),
          ],
          ..._amenities.map((a) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _activeChip(a.replaceAll('_', ' '),
                    () => setState(() => _amenities.remove(a))),
              )),
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'rating', child: Text(l10n.rating_high_low)),
              PopupMenuItem(value: 'price', child: Text(l10n.price_low_high)),
              PopupMenuItem(
                  value: 'distance',
                  child: Text(l10n.distance_city_centre),
                ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(_sortBy == 'rating'
                      ? 'Rating'
                      : _sortBy == 'price'
                          ? 'Price'
                          : 'Distance'),
                  const Icon(Icons.arrow_drop_down_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityDropdown() {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      initialValue: _city,
      onSelected: (v) => setState(() => _city = v),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'Ahmedabad', child: Text(l10n.ahmedabad)),
        PopupMenuItem(value: 'Mumbai', child: Text(l10n.mumbai)),
        PopupMenuItem(value: 'Bengaluru', child: Text(l10n.bengaluru)),
        PopupMenuItem(value: 'Hyderabad', child: Text(l10n.hyderabad)),
        PopupMenuItem(value: 'Pune', child: Text(l10n.pune)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(_city),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GroundFilterSheet(
        pitchType: _pitchType,
        maxPrice: _maxPrice,
        amenities: _amenities.toList(),
      ),
    );
    if (result != null) {
      setState(() {
        _pitchType = result['pitch_type'] as String?;
        _maxPrice = result['max_price'] as int?;
        _amenities = Set<String>.from((result['amenities'] as List?) ?? []);
      });
    }
  }

  Widget _buildList(BuildContext context) {
    return StreamBuilder<List<Ground>>(
      stream: _service.searchGrounds(
        city: _city,
        pitchType: _pitchType,
        maxPrice: _maxPrice,
        amenities: _amenities.toList(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.errCouldNotLoadGrounds,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        final grounds = (snapshot.data ?? [])
            .where((g) => groundMatchesQuery(
                  query: _search,
                  name: g.name,
                  city: g.city,
                  address: g.address,
                  pitchType: g.pitchType,
                ))
            .toList();
        if (grounds.isEmpty) return _emptyState(context);
        grounds.sort(_comparator);
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: grounds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => GroundCard(ground: grounds[index]),
          ),
        );
      },
    );
  }

  int Function(Ground, Ground) get _comparator {
    switch (_sortBy) {
      case 'price':
        return (a, b) => a.priceWeekdayHourly.compareTo(b.priceWeekdayHourly);
      case 'distance':
        // No location permission yet, so "distance" is measured from the
        // selected city's centre — see lib/core/geo.dart.
        final (cLat, cLng) = centreOf(_city);
        double km(Ground g) => distanceKm(cLat, cLng, g.lat, g.lng);
        return (a, b) => km(a).compareTo(km(b));
      case 'rating':
      default:
        return (a, b) => b.avgRating.compareTo(a.avgRating);
    }
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_cricket_rounded,
                  size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(l10n.no_grounds_match_your_filters,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.try_removing_a_filter_or_switch,
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

/// Shared list-item widget for grounds.
class GroundCard extends StatelessWidget {
  const GroundCard({super.key, required this.ground});
  final Ground ground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            GroundDetailScreen.route,
            arguments: ground.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ground.coverPhotoUrl.isEmpty
                      ? _placeholderPhoto()
                      : CachedNetworkImage(
                          imageUrl: ground.coverPhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholderPhoto(),
                          errorWidget: (_, __, ___) => _placeholderPhoto(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ground.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (ground.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded,
                                size: 16, color: Color(0xFF0EA5E9)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          ground.city,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ground.pitchType,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          l10n.hourlyRate(ground.priceWeekdayHourly),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.primary),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFB400)),
                        const SizedBox(width: 2),
                        Text(
                          ground.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        if (ground.reviewCount > 0) ...[
                          const SizedBox(width: 2),
                          Text('(${ground.reviewCount})',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderPhoto() {
    return Container(
      color: AppTheme.surfaceSoft,
      child: const Icon(Icons.sports_cricket_rounded,
          size: 36, color: AppTheme.textSecondary),
    );
  }
}