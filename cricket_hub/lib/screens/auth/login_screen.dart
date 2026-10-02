import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';
import 'otp_screen.dart';

/// Screen 1 of UI/UX doc: Login/Signup.
/// Phone OTP (primary) + Google Sign-In.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final bool _isCountryCode = true;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    final fullNumber = _isCountryCode && !phone.startsWith('+')
        ? '+91$phone' // default India; change if needed
        : phone;

    auth.sendOtp(fullNumber, onCodeSent: (verificationId) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        OtpScreen.route,
        arguments: {
          'verificationId': verificationId,
          'phoneNumber': fullNumber,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.sports_cricket,
                  size: 88, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('Welcome to CricketHub',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Local cricket. Pro level.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Phone number input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_android),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(auth.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.danger)),
                ),

              // Send OTP button
              ElevatedButton(
                onPressed: auth.isLoading ? null : _sendOtp,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send OTP'),
              ),

              const SizedBox(height: 24),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('OR',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),

              // Google Sign-In
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final ok =
                            await auth.signInWithGoogle();
                        if (ok && context.mounted) {
                          Navigator.pushReplacementNamed(
                              context, MainShell.route);
                        }
                      },
              ),

              const SizedBox(height: 32),
              const Text(
                'By continuing you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
