import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/ground_model.dart';
import '../models/umpire_model.dart';

/// Platform-admin operations: verifying the listings that owners and umpires
/// submit.
///
/// Until now `status: 'pending_verification'` was a dead end — nothing in the
/// app could look at that queue, so the only way to activate a ground was the
/// Firebase Console. That is why Phase 3 could not go live.
///
/// Admin identity is a `/admins/{uid}` document (see `isAdmin()` in
/// firestore.rules). Rules allow an admin exactly
/// `['verified', 'status', 'updated_at']` on grounds and umpires, which is
/// what the approve/send-back helpers below write — nothing else.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection(AppConstants.adminsCol);
  CollectionReference<Map<String, dynamic>> get _grounds =>
      _db.collection(AppConstants.groundsCol);
  CollectionReference<Map<String, dynamic>> get _umpires =>
      _db.collection(AppConstants.umpiresCol);

  /// Streams whether [uid] is a platform admin. Deny-by-default: no document,
  /// no access.
  Stream<bool> isAdminStream(String uid) {
    return _admins.doc(uid).snapshots().map((snap) => snap.exists);
  }

  /// One-shot check, for guarding a route.
  Future<bool> isAdmin(String uid) async {
    final snap = await _admins.doc(uid).get();
    return snap.exists;
  }

  /// Grounds waiting for a decision, oldest submission first.
  ///
  /// No `orderBy` on purpose: the rules allow it (each doc is individually
  /// readable by an admin), but a combined `where` + `orderBy` would need a
  /// composite index that is not in `firestore.indexes.json`. The queue is
  /// small, so it is sorted client-side.
  Stream<List<Ground>> pendingGroundsStream() {
    return _grounds
        .where('status', isEqualTo: 'pending_verification')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Ground.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return at.compareTo(bt);
      });
      return list;
    });
  }

  /// Umpire profiles waiting for a decision.
  Stream<List<Umpire>> pendingUmpiresStream() {
    return _umpires
        .where('status', isEqualTo: 'pending_verification')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Umpire.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return at.compareTo(bt);
      });
      return list;
    });
  }

  // ---------------------------------------------------------------------------
  // Ground decisions
  // ---------------------------------------------------------------------------

  /// Publishes the listing: it becomes visible in the marketplace.
  Future<void> approveGround(String groundId) {
    return _grounds.doc(groundId).update({
      'verified': true,
      'status': 'active',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Sends the listing back to the owner as a draft so they can fix it.
  Future<void> sendBackGround(String groundId) {
    return _grounds.doc(groundId).update({
      'verified': false,
      'status': 'draft',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Umpire decisions
  // ---------------------------------------------------------------------------

  Future<void> approveUmpire(String umpireUid) {
    return _umpires.doc(umpireUid).update({
      'verified': true,
      'status': 'active',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendBackUmpire(String umpireUid) {
    return _umpires.doc(umpireUid).update({
      'verified': false,
      'status': 'draft',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
