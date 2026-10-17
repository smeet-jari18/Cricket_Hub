import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/payout_model.dart';

/// Reads `payout_ledger/{ownerUid}/weeks/{weekStartIso}`.
///
/// `weeklyPayoutDigest` (functions/index.js) has been writing these documents
/// every Monday since Phase 3, and the rules allow an owner to read their own
/// ledger — but the app had no reader, so an owner could never see what they
/// were owed. Field names below mirror the Cloud Function exactly.
class PayoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PayoutWeek>> payoutWeeksStream(String ownerUid, {int limit = 26}) {
    return _db
        .collection(AppConstants.payoutLedgerCol)
        .doc(ownerUid)
        .collection(AppConstants.payoutWeeksSubCol)
        .orderBy('week_start', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PayoutWeek.fromFirestore(d.id, d.data()))
            .toList());
  }
}
