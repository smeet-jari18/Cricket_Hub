import '../../core/app_constants.dart';
import '../../models/ground_model.dart';

/// Argument bundle passed to BookingCheckoutScreen — precomputed by the
/// calendar / detail screen so the checkout doesn't have to query again.
class CheckoutArgs {
  const CheckoutArgs({
    required this.ground,
    required this.dateIso,
    required this.slotStart,
    required this.slotEnd,
    required this.amountPaise,
    required this.platformFeePaise,
  });

  final Ground ground;
  final String dateIso;
  final String slotStart;
  final String slotEnd;
  final int amountPaise;
  final int platformFeePaise;

  /// Build CheckoutArgs from a Ground + date + slot.
  factory CheckoutArgs.forSlot({
    required Ground ground,
    required String dateIso,
    required String slotStart,
    required String slotEnd,
  }) {
    final hours = ground.slotDurationMinutes ~/ 60;
    final amountPaise =
        ground.hourlyRateFor(DateTime.parse(dateIso)) * 100 * hours;
    final platformFeePaise = (amountPaise * AppConstants.platformFeePct).round();
    return CheckoutArgs(
      ground: ground,
      dateIso: dateIso,
      slotStart: slotStart,
      slotEnd: slotEnd,
      amountPaise: amountPaise,
      platformFeePaise: platformFeePaise,
    );
  }
}