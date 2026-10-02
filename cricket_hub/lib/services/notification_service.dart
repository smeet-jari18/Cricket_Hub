import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_navigator.dart';

/// FCM match-follow service. Match topics keep fan delivery efficient; a
/// private Firestore follow document lets the UI show the user's preference.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;
  String? _pendingMatchId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _openMessage(initialMessage);
    } catch (error) {
      debugPrint('FCM initial message unavailable: $error');
    }
  }

  Stream<bool> followingMatchStream(String uid, String matchId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following_matches')
        .doc(matchId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> followMatch({required String uid, required String matchId}) async {
    _ensureSupportedPlatform();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw StateError('Sign in to follow this match.');
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!allowed) throw StateError('Allow notifications in your device settings to follow this match.');

    final topic = _topicFor(matchId);
    await _messaging.subscribeToTopic(topic);
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('following_matches')
          .doc(matchId)
          .set({
        'match_id': matchId,
        'topic': topic,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _messaging.unsubscribeFromTopic(topic);
      rethrow;
    }
  }

  Future<void> unfollowMatch({required String uid, required String matchId}) async {
    _ensureSupportedPlatform();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw StateError('Sign in to manage match notifications.');
    }
    final topic = _topicFor(matchId);
    await _messaging.unsubscribeFromTopic(topic);
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('following_matches')
          .doc(matchId)
          .delete();
    } catch (_) {
      await _messaging.subscribeToTopic(topic);
      rethrow;
    }
  }

  /// Reattaches this installation to follow topics after reinstall/session
  /// restoration. FCM's topic subscriptions are installation-specific.
  Future<void> resubscribeFollowedMatches(String uid) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid) return;
    try {
      final settings = await _messaging.getNotificationSettings();
      final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return;
      final follows = await _db
          .collection('users')
          .doc(uid)
          .collection('following_matches')
          .get();
      for (final follow in follows.docs) {
        final matchId = (follow.data()['match_id'] ?? follow.id) as String;
        await _messaging.subscribeToTopic(_topicFor(matchId));
      }
    } catch (error) {
      debugPrint('Could not restore followed match topics: $error');
    }
  }

  /// Called by the authenticated app shell after Firebase Auth has restored.
  String? takePendingMatchId() {
    if (FirebaseAuth.instance.currentUser == null) return null;
    final matchId = _pendingMatchId;
    _pendingMatchId = null;
    return matchId;
  }

  void _showForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'CricketHub update';
    final body = message.notification?.body ?? 'There is new match activity.';
    appScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$title · $body'),
        action: message.data['matchId'] is String
            ? SnackBarAction(
                label: 'OPEN',
                onPressed: () => _openMatchId(message.data['matchId'] as String),
              )
            : null,
      ),
    );
  }

  void _openMessage(RemoteMessage message) {
    final matchId = message.data['matchId'] ?? message.data['match_id'];
    if (matchId is String && matchId.isNotEmpty) _openMatchId(matchId);
  }

  void _openMatchId(String matchId) {
    if (FirebaseAuth.instance.currentUser == null) {
      _pendingMatchId = matchId;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        _pendingMatchId = matchId;
      } else {
        navigator.pushNamed('/live-match', arguments: matchId);
      }
    });
  }

  String _topicFor(String matchId) => 'match_${matchId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';

  void _ensureSupportedPlatform() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      throw UnsupportedError('Match push notifications are available on Android and iOS.');
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
