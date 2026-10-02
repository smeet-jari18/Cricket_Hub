import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';
import 'profile_setup_screen.dart';

/// Screen 2: 6-digit OTP verification.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  static const String route = '/otp';

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  String _verificationId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Receive the verificationId sent from the Login screen.
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _verificationId.isEmpty) {
      _verificationId = (args['verificationId'] ?? '') as String;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_verificationId, _otpController.text);
    if (!mounted) return;

    if (ok) {
      // New user? -> Profile setup. Otherwise -> Home.
      Navigator.pushReplacementNamed(
        context,
        auth.needsProfileSetup ? ProfileSetupScreen.route : MainShell.route,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phone = (args?['phoneNumber'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to\n$phone',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '••••••',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(auth.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            ElevatedButton(
              onPressed: auth.isLoading ? null : _verify,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
