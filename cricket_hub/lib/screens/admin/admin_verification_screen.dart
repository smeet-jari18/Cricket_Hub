import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../models/umpire_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';

/// Platform-admin queue: approve or send back the listings that owners and
/// umpires submit.
///
/// Before this screen existed, `pending_verification` entries could only be
/// cleared from the Firebase Console — no ground could ever go live through
/// the product itself.
///
/// Access: the route is reachable by anyone, but the screen checks
/// `/admins/{uid}` first and shows "not an admin" otherwise. Firestore rules
/// are the real gate: non-admins cannot read pending documents, so even a
/// forced navigation shows an empty/denied state rather than the queue.
class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  static const String route = '/admin-verification';

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification queue')),
        body: const Center(child: Text('Please sign in.')),
      );
    }

    return StreamBuilder<bool>(
      stream: context.read<AdminService>().isAdminStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Verification queue')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Verification queue')),
            body: const _NotAdmin(),
          );
        }
        return const _AdminTabs();
      },
    );
  }
}

class _NotAdmin extends StatelessWidget {
  const _NotAdmin();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Admins only',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'This queue is for CricketHub staff. Ask an existing admin to '
              'add you under /admins in the Firebase Console.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verification queue'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Grounds'),
              Tab(text: 'Umpires'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroundQueue(),
            _UmpireQueue(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Grounds
// -----------------------------------------------------------------------------

class _GroundQueue extends StatelessWidget {
  const _GroundQueue();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ground>>(
      stream: context.read<AdminService>().pendingGroundsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorBox(error: snapshot.error);
        }
        final grounds = snapshot.data ?? const <Ground>[];
        if (grounds.isEmpty) {
          return const _Empty(
            icon: Icons.stadium_outlined,
            title: 'No grounds waiting',
            body: 'New submissions from ground owners will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grounds.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GroundCard(ground: grounds[i]),
          ),
        );
      },
    );
  }
}

class _GroundCard extends StatefulWidget {
  const _GroundCard({required this.ground});

  final Ground ground;

  @override
  State<_GroundCard> createState() => _GroundCardState();
}

class _GroundCardState extends State<_GroundCard> {
  bool _busy = false;

  Future<void> _decide({required bool approve}) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminService>();
    setState(() => _busy = true);
    try {
      if (approve) {
        await admin.approveGround(widget.ground.id);
      } else {
        await admin.sendBackGround(widget.ground.id);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${widget.ground.name} is live.'
                : '${widget.ground.name} sent back to the owner.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.ground;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${g.city} · ${g.address}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(g.pitchType.toUpperCase()),
                _Pill('₹${g.priceWeekdayHourly}/hr'),
                _Pill('₹${g.priceWeekendHourly}/wknd'),
                _Pill('${g.openTime}–${g.closeTime}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _decide(approve: false),
                    child: const Text('Send back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _decide(approve: true),
                    child: Text(_busy ? 'Working…' : 'Approve & publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Umpires
// -----------------------------------------------------------------------------

class _UmpireQueue extends StatelessWidget {
  const _UmpireQueue();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Umpire>>(
      stream: context.read<AdminService>().pendingUmpiresStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorBox(error: snapshot.error);
        }
        final umpires = snapshot.data ?? const <Umpire>[];
        if (umpires.isEmpty) {
          return const _Empty(
            icon: Icons.record_voice_over_outlined,
            title: 'No umpires waiting',
            body: 'New umpire profiles will appear here for verification.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: umpires.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UmpireCard(umpire: umpires[i]),
          ),
        );
      },
    );
  }
}

class _UmpireCard extends StatefulWidget {
  const _UmpireCard({required this.umpire});

  final Umpire umpire;

  @override
  State<_UmpireCard> createState() => _UmpireCardState();
}

class _UmpireCardState extends State<_UmpireCard> {
  bool _busy = false;

  Future<void> _decide({required bool approve}) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminService>();
    setState(() => _busy = true);
    try {
      if (approve) {
        await admin.approveUmpire(widget.umpire.uid);
      } else {
        await admin.sendBackUmpire(widget.umpire.uid);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${widget.umpire.displayName} can take bookings now.'
                : '${widget.umpire.displayName} sent back for edits.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.umpire;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${u.city} · ${u.experienceYears} yrs · ₹${u.hourlyRate}/hr',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (u.bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                u.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
            if (u.certifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in u.certifications) _Pill(c.name),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _decide(approve: false),
                    child: const Text('Send back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _decide(approve: true),
                    child: Text(_busy ? 'Working…' : 'Approve umpire'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared bits
// -----------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppTheme.danger),
            const SizedBox(height: 12),
            const Text(
              'Could not load the queue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
