import 'package:flutter/material.dart';

import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';

/// Bottom sheet for filter selection. Returns a Map or null on cancel.
class GroundFilterSheet extends StatefulWidget {
  const GroundFilterSheet({
    super.key,
    this.pitchType,
    this.maxPrice,
    this.amenities = const [],
  });

  final String? pitchType;
  final int? maxPrice;
  final List<String> amenities;

  @override
  State<GroundFilterSheet> createState() => _GroundFilterSheetState();
}

class _GroundFilterSheetState extends State<GroundFilterSheet> {
  String? _pitchType;
  late RangeValues _priceRange;
  late Set<String> _amenities;

  static const _pitchTypes = ['turf', 'matting', 'concrete'];

  @override
  void initState() {
    super.initState();
    _pitchType = widget.pitchType;
    _priceRange = RangeValues(
      0,
      widget.maxPrice?.toDouble() ?? 5000,
    );
    _amenities = widget.amenities.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _section('Pitch type'),
              Wrap(
                spacing: 8,
                children: _pitchTypes
                    .map((p) => _chip(
                          label: p,
                          selected: _pitchType == p,
                          onTap: () => setState(
                              () => _pitchType = _pitchType == p ? null : p),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _section('Max price (₹/hour)'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 5000,
                divisions: 50,
                labels: RangeLabels(
                  '₹${_priceRange.start.round()}',
                  '₹${_priceRange.end.round()}',
                ),
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              const SizedBox(height: 12),
              _section('Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.standardAmenities
                    .map((a) => _chip(
                          label: a.replaceAll('_', ' '),
                          selected: _amenities.contains(a),
                          onTap: () => setState(() {
                            if (_amenities.contains(a)) {
                              _amenities.remove(a);
                            } else {
                              _amenities.add(a);
                            }
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'pitch_type': _pitchType,
                          'max_price': _priceRange.end.round(),
                          'amenities': _amenities.toList(),
                        });
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _chip(
      {required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}