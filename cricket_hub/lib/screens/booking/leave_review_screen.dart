import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';

/// Arguments for [LeaveReviewScreen] — either a ground or an umpire target.
class LeaveReviewArgs {
  const LeaveReviewArgs({
    required this.bookingId,
    required this.groundId,
    required this.groundName,
    this.umpireUid,
  });

  final String bookingId;
  final String groundId;
  final String groundName;
  final String? umpireUid;

  bool get isUmpireReview => umpireUid != null && umpireUid!.isNotEmpty;
}

/// Sprint 11's `leave_review_screen.dart`.
class LeaveReviewScreen extends StatelessWidget {
  const LeaveReviewScreen({super.key});

  static const String route = '/leave-review';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! LeaveReviewArgs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leave a review')),
        body: const Center(child: Text('No booking selected.')),
      );
    }
    return _Body(args: args);
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.args});

  final LeaveReviewArgs args;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const int _maxChars = 500;

  final TextEditingController _text = TextEditingController();
  int _rating = 0;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.args.bookingId.trim().isEmpty) {
      // Rules reject a review without a completed booking — fail early with a
      // readable message instead of a PERMISSION_DENIED from Firestore.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reviews come from a completed booking.'),
        ),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a rating from 1 to 5 first.')),
      );
      return;
    }
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    setState(() => _busy = true);
    final service = context.read<ReviewService>();
    try {
      if (widget.args.isUmpireReview) {
        await service.submitUmpireReview(
          umpireUid: widget.args.umpireUid!,
          bookingId: widget.args.bookingId,
          reviewerUid: user.uid,
          reviewerName: user.displayName,
          rating: _rating,
          text: _text.text.trim(),
        );
      } else {
        await service.submitGroundReview(
          groundId: widget.args.groundId,
          bookingId: widget.args.bookingId,
          reviewerUid: user.uid,
          reviewerName: user.displayName,
          rating: _rating,
          text: _text.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for the review!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post review: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.args.groundName.isEmpty
        ? 'this ground'
        : widget.args.groundName;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'How was $name?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Your rating helps other organizers pick a good ground.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Center(
            child: RatingStarsInput(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0 ? 'Tap a star' : _ratingLabel(_rating),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _text,
            maxLines: 5,
            maxLength: _maxChars,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Pitch quality, lights, changing rooms, staff…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Posting…' : 'Post review'),
          ),
        ],
      ),
    );
  }

  static String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Below average';
      case 3:
        return 'Decent';
      case 4:
        return 'Good';
      default:
        return 'Excellent';
    }
  }
}
