import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../services/booking_service.dart';

/// Sprint 9's `owner_qr_scanner_screen.dart`.
///
/// Closes the loop on FR-BOOK-03: the organizer's QR was generated and shown,
/// `validateBookingQR` existed on the server and `BookingService.validateQr`
/// existed on the client, but there was no scanner — so a QR could never
/// actually be verified at the ground.
class OwnerQrScannerScreen extends StatefulWidget {
  const OwnerQrScannerScreen({super.key});

  static const String route = '/owner-qr-scanner';

  @override
  State<OwnerQrScannerScreen> createState() => _OwnerQrScannerScreenState();
}

class _OwnerQrScannerScreenState extends State<OwnerQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _busy = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _result != null) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    setState(() => _busy = true);
    // Grab the service before the first await so no BuildContext crosses an
    // async gap.
    final bookings = context.read<BookingService>();
    try {
      await _controller.stop();
      final res = await bookings.validateQr(raw);
      if (!mounted) return;
      setState(() {
        _result = res;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  void _scanAgain() {
    setState(() {
      _result = null;
      _error = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan booking QR')),
      body: kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
          ? _unsupported()
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                      ),
                      const _ScanFrame(),
                      if (_busy)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                _sheet(),
              ],
            ),
    );
  }

  Widget _unsupported() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Camera scanning runs in the Android and iOS app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Open CricketHub on a phone to verify a booking QR.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheet() {
    if (_error != null) {
      return _panel(
        color: AppTheme.danger,
        icon: Icons.error_outline_rounded,
        title: 'Not valid',
        body: _error!,
        action: TextButton(
          onPressed: _scanAgain,
          child: const Text('Scan again'),
        ),
      );
    }
    if (_result != null) {
      final b = _result!;
      return _panel(
        color: AppTheme.boundaryFour,
        icon: Icons.verified_rounded,
        title: 'Booking verified',
        body: [
          if (b['resourceName'] != null) '${b['resourceName']}',
          if (b['date'] != null && b['slotStart'] != null)
            '${b['date']} · ${b['slotStart']}–${b['slotEnd']}',
          if (b['organizerName'] != null) 'by ${b['organizerName']}',
        ].where((s) => s.isNotEmpty).join('\n'),
        action: TextButton(
          onPressed: _scanAgain,
          child: const Text('Scan next'),
        ),
      );
    }
    return _panel(
      color: AppTheme.textPrimary,
      icon: Icons.qr_code_scanner_rounded,
      title: 'Point at the organizer’s QR',
      body: 'The booking is confirmed only if the code is valid and belongs '
          'to one of your grounds.',
    );
  }

  Widget _panel({
    required Color color,
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        color: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
