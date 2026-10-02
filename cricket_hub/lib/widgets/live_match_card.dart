import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/match_model.dart';

/// Horizontal live-match card on the home feed.
class LiveMatchCard extends StatelessWidget {
  final CricketMatch match;
  final double width;
  final VoidCallback onTap;

  const LiveMatchCard({
    super.key,
    required this.match,
    this.width = 292,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overs = '${match.ballsBowled ~/ 6}.${match.ballsBowled % 6}';

    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LivePill(),
                    const Spacer(),
                    Text(
                      '${match.totalOvers} overs',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Divider(height: 1),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TeamName(name: match.teamAName),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            _TeamName(name: match.teamBName),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${match.venueRuns}/${match.venueWickets}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$overs ov',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 15, color: AppTheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Follow live',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            letterSpacing: 0.1,
                          ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: AppTheme.danger),
          SizedBox(width: 6),
          Text(
            'LIVE NOW',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  final String name;

  const _TeamName({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
