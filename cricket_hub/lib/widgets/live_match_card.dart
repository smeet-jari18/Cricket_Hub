import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/match_model.dart';

/// "Live Now" carousel card on the Home screen (UI/UX doc Screen 1).
class LiveMatchCard extends StatelessWidget {
  final CricketMatch match;
  final double width;
  final VoidCallback onTap;

  const LiveMatchCard({
    super.key,
    required this.match,
    this.width = 280,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final balls = match.ballsBowled;
    final oversDisplay = '${balls ~/ 6}.${balls % 6}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIVE indicator
            const Row(
              children: [
                Icon(Icons.circle, color: AppTheme.danger, size: 8),
                SizedBox(width: 6),
                Text('LIVE',
                    style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
              ],
            ),
            const Spacer(),
            Text(
              match.teamAName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'vs',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
            Text(
              match.teamBName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${match.venueRuns}/${match.venueWickets}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$oversDisplay ov',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
