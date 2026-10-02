import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Central auth state for the whole app (Provider).
/// Screens call: context.watch<AuthProvider>()
class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _firebaseUser;
  AppUser? _appUser;
  bool _loading = false;
  bool _authInitialized = false;
  bool _profileLoaded = false;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUser?>? _profileSubscription;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;

  /// Splash waits for Firebase Auth and, when signed in, the profile document.
  bool get isReady =>
      _authInitialized && (_firebaseUser == null || _profileLoaded);

  bool get needsProfileSetup => _firebaseUser != null &&
      _profileLoaded &&
      (_appUser == null || !_appUser!.isProfileComplete);

  AuthProvider() {
    _authSubscription = _service.authStateChanges.listen(
      (user) {
        _firebaseUser = user;
        _appUser = null;
        _authInitialized = true;
        _profileLoaded = user == null;
        _profileSubscription?.cancel();

        if (user != null) {
          _profileSubscription = _service.userDocStream(user.uid).listen(
            (profile) {
              _appUser = profile;
              _profileLoaded = true;
              notifyListeners();
            },
            onError: (Object error) {
              _profileLoaded = true;
              _errorMessage = 'Could not load your profile. Please try again.';
              notifyListeners();
            },
          );
        }
        notifyListeners();
      },
      onError: (Object error) {
        _firebaseUser = null;
        _appUser = null;
        _authInitialized = true;
        _profileLoaded = true;
        _errorMessage = 'Could not restore your sign-in session.';
        notifyListeners();
      },
    );
  }

  // ---- wrapped service calls (loading + error state for UI) ----

  Future<void> sendOtp(String phoneNumber,
      {required void Function(String verificationId) onCodeSent}) async {
    _setLoading(true);
    try {
      await _service.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        onError: (message) {
          _setError(message);
        },
      );
    } catch (e) {
      _setError('Could not send OTP. Please try again.');
    }
  }

  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    _setLoading(true);
    try {
      await _service.verifyOtp(verificationId: verificationId, smsCode: smsCode);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Wrong OTP or expired. Please try again.');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _service.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Google sign-in failed. Check your connection and try again.');
      return false;
    }
  }

  Future<void> completeProfile({
    required String name,
    required String battingStyle,
    required String bowlingStyle,
  }) async {
    _setLoading(true);
    try {
      await _service.completeProfile(
        name: name,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Could not save your profile. Please try again.');
      rethrow;
    }
  }

  Future<void> signOut() => _service.signOut();

  void _setLoading(bool value) {
    _loading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _loading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
