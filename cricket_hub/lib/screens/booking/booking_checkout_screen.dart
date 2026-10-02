import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import 'booking_success_screen.dart';
import 'checkout_args.dart';

/// Order summary + payment method selection + Razorpay trigger.
class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key, required this.args});

  static const String route = '/bookings/checkout';
  final CheckoutArgs args;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  String _paymentMethod = 'razorpay'; // 'razorpay' | 'cod'
  String _notes = '';
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final total = args.amountPaise + args.platformFeePaise;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _section('Order summary'),
          _orderCard(args),
          const SizedBox(height: 20),
          _section('Payment method'),
          _paymentRadio('razorpay', 'Online (UPI / Card / NetBanking)',
              'Razorpay secure checkout', Icons.credit_card_rounded),
          const SizedBox(height: 8),
          _paymentRadio('cod', 'Cash on Ground',
              'Pay at the venue. Booking is held until owner confirms.',
              Icons.payments_outlined),
          const SizedBox(height: 20),
          _section('Add a note'),
          TextField(
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g., "Tournament semi-final, expect 25 players"',
            ),
            onChanged: (v) => setState(() => _notes = v),
          ),
          const SizedBox(height: 20),
          _priceCard(args, total),
          const SizedBox(height: 24),
          Text(
            'By tapping "Pay & Book", you agree to the cancellation policy '
            '(full refund up to 24h before, 50% up to 12h before, no refund thereafter).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _processing ? null : _onPay,
            child: _processing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_paymentMethod == 'cod'
                    ? 'Confirm booking (Cash on Ground)'
                    : 'Pay & Book  •  ₹${(total / 100).round()}'),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _orderCard(CheckoutArgs args) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(args.ground.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${args.ground.city} • ${args.ground.pitchType}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary)),
            const Divider(height: 24),
            _row('Date', _humanDate(args.dateIso)),
            _row('Time', '${args.slotStart} – ${args.slotEnd}'),
            _row(
                'Duration', '${args.ground.slotDurationMinutes ~/ 60} hours'),
          ],
        ),
      ),
    );
  }

  Widget _priceCard(CheckoutArgs args, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _priceRow('Subtotal', args.amountPaise),
            const SizedBox(height: 8),
            _priceRow('Platform fee (5%)', args.platformFeePaise),
            const Divider(height: 24),
            _priceRow('Total', total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, int paise, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
            )),
        Text('₹${(paise / 100).round()}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 18 : 14,
            )),
      ],
    );
  }

  Widget _paymentRadio(
      String value, String title, String subtitle, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      )),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'razorpay'),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _humanDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  // ---------------------------------------------------------------------------
  // Payment flow
  // ---------------------------------------------------------------------------

  Future<void> _onPay() async {
    setState(() => _processing = true);
    final auth = context.read<AuthProvider>();
    final user = auth.appUser;
    if (user == null) {
      _snack('Please sign in to book');
      setState(() => _processing = false);
      return;
    }

    final bookingService = context.read<BookingService>();
    final args = widget.args;

    try {
      if (_paymentMethod == 'cod') {
        await bookingService.createCashOnGroundBooking(
          groundId: args.ground.id,
          groundName: args.ground.name,
          ownerUid: args.ground.ownerUid,
          ownerName: 'Ground Owner', // Phase 3.5: denormalize on ground doc
          organizerUid: user.uid,
          organizerName: user.displayName,
          date: args.dateIso,
          slotStart: args.slotStart,
          slotEnd: args.slotEnd,
          durationMinutes: args.ground.slotDurationMinutes,
          amountPaise: args.amountPaise,
          platformFeePaise: args.platformFeePaise,
          notes: _notes,
        );
        if (!mounted) return;
        _snack('Booking held. Pay at the venue.');
        Navigator.pop(context);
        return;
      }

      // Online (Razorpay)
      final bookingId = await bookingService.createHold(
        groundId: args.ground.id,
        groundName: args.ground.name,
        ownerUid: args.ground.ownerUid,
        ownerName: 'Ground Owner',
        organizerUid: user.uid,
        organizerName: user.displayName,
        date: args.dateIso,
        slotStart: args.slotStart,
        slotEnd: args.slotEnd,
        durationMinutes: args.ground.slotDurationMinutes,
        amountPaise: args.amountPaise,
        platformFeePaise: args.platformFeePaise,
        notes: _notes,
      );

      final order = await bookingService.createRazorpayOrder(bookingId);

      final paymentService = context.read<PaymentService>();
      paymentService.initialize();
      final session = paymentService.openCheckout(
        bookingId: bookingId,
        orderId: order['orderId'] as String,
        razorpayKeyId: order['razorpayKeyId'] as String,
        amountInPaise: (order['amountInPaise'] as num).toInt(),
        organizerName: user.displayName.isEmpty
            ? 'CricketHub user'
            : user.displayName,
        organizerEmail: 'user@example.com', // Phase 3.5: add email to users
        organizerPhone: user.phoneNumber,
        description: 'Ground booking at ${args.ground.name}',
      );

      final payment = await session.completion;
      if (!mounted) return;
      if (payment.verified) {
        Navigator.pushReplacementNamed(
          context,
          BookingSuccessScreen.route,
          arguments: bookingId,
        );
      } else {
        _snack(payment.reason.isEmpty ? 'Payment failed' : payment.reason);
      }
    } catch (e) {
      _snack('Could not start checkout. Try again.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}