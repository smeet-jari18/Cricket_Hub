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
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;
  bool get needsProfileSetup =>
      isLoggedIn && (_appUser == null || !_appUser!.isProfileComplete);

  AuthProvider() {
    // Listen: login/logout happens -> rebuild the app navigation.
    _service.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user == null) {
        _appUser = null;
      } else {
        // Also listen to the user's Firestore profile document.
        _service.userDocStream(user.uid).listen((profile) {
          _appUser = profile;
          notifyListeners();
        });
      }
      notifyListeners();
    });
  }

  // ---- wrapped service calls (loading + error state for UI) ----

  Future<void> sendOtp(String phoneNumber,
      {required void Function(String verificationId) onCodeSent}) async {
    _setLoading(true);
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
  }

  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    _setLoading(true);
    try {
      await _service.verifyOtp(verificationId: verificationId, smsCode: smsCode);
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
      return true;
    } catch (e) {
      _setError('Google sign-in failed. Try again.');
      return false;
    }
  }

  Future<void> completeProfile({
    required String name,
    required String battingStyle,
    required String bowlingStyle,
  }) async {
    _setLoading(true);
    await _service.completeProfile(
      name: name,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
    );
    _setLoading(false);
  }

  Future<void> signOut() => _service.signOut();

  void _setLoading(bool value) {
    _loading = value;
    _errorMessage = null;
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
}
