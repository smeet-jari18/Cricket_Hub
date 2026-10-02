import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';

class CareerStatsScreen extends StatelessWidget {
  const CareerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final stats = user?.careerStats ?? const <String, dynamic>{};
    final matches = _value(stats, 'matches_played');
    final runs = _value(stats, 'runs');
    final wickets = _value(stats, 'wickets');
    final recent = _mapList(stats['recent_matches']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryContainer,
              backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                  ? NetworkImage(user!.avatarUrl)
                  : null,
              child: (user?.avatarUrl.isNotEmpty ?? false)
                  ? null
                  : const Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'Your career',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 3),
                  Text(
                    '${user?.battingStyle.isNotEmpty == true ? user!.battingStyle : 'Player'}'
                    '${user?.bowlingStyle.isNotEmpty == true ? '  ·  ${user!.bowlingStyle}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 21),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _HeroStatCard(
                label: 'MATCHES',
                value: '$matches',
                supporting: 'Career appearances',
                icon: Icons.sports_cricket_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HeroStatCard(
                label: 'TOTAL RUNS',
                value: '$runs',
                supporting: '${_value(stats, 'fifties')} 50s · ${_value(stats, 'hundreds')} 100s',
                icon: Icons.sports_baseball_outlined,
                color: AppTheme.accentText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _StatCard(label: 'BATTING AVERAGE', value: _decimal(stats['batting_average'])),
            _StatCard(label: 'STRIKE RATE', value: _decimal(stats['strike_rate'])),
            _StatCard(label: 'WICKETS', value: '$wickets'),
            _StatCard(label: 'ECONOMY', value: _decimal(stats['economy'])),
            _StatCard(label: 'HIGH SCORE', value: '${_value(stats, 'high_score')}'),
            _StatCard(label: 'BEST BOWLING', value: (stats['best_bowling'] ?? '—') as String),
            _StatCard(label: '4s / 6s', value: '${_value(stats, 'fours')} / ${_value(stats, 'sixes')}'),
            _StatCard(label: '5-WICKET HAULS', value: '${_value(stats, 'five_wicket_hauls')}'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Recent form',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Text('LAST ${recent.length.clamp(0, 5)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    )),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppTheme.primary),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      matches == 0
                          ? 'Your career card updates automatically after a completed match records your player profile.'
                          : 'No recent match details are available yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.take(5).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      child: const Icon(Icons.sports_cricket, color: AppTheme.primary, size: 19),
                    ),
                    title: Text(
                      (entry['opponent'] ?? 'Match') as String,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      '${_value(entry, 'runs')} runs · ${_value(entry, 'wickets')} wickets · ${(entry['result'] ?? 'Played') as String}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  ),
                ),
              )),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String supporting;
  final IconData icon;
  final Color color;

  const _HeroStatCard({
    required this.label,
    required this.value,
    required this.supporting,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: color,
                    )),
            const SizedBox(height: 5),
            Text(supporting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    )),
            const SizedBox(height: 9),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
          ],
        ),
      ),
    );
  }
}

int _value(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

String _decimal(Object? value) {
  if (value == null) return '—';
  if (value is num) return value.toStringAsFixed(2);
  return '—';
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! Iterable) return const [];
  return value.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
}
