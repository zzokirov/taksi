import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isBarberView;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onReview;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isBarberView = false,
    this.onCancel,
    this.onReschedule,
    this.onConfirm,
    this.onReject,
    this.onComplete,
    this.onReview,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
      case 'no_show':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusText() {
    switch (appointment.status) {
      case 'confirmed':
        return "Tasdiqlangan";
      case 'pending':
        return "Kutilmoqda";
      case 'completed':
        return "Bajarildi";
      case 'cancelled':
        return "Bekor qilingan";
      case 'no_show':
        return "Kelmadi";
      default:
        return appointment.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date & Time + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${appointment.formattedDate}  ${appointment.formattedTime}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(), width: 0.8),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),

            // Service details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBarberView
                            ? "Mijoz: ${appointment.customerName} (${appointment.customerPhone})"
                            : "Sartarosh: ${appointment.barberName} (${appointment.barbershopName ?? ''})",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${currencyFormatter.format(appointment.servicePrice)} UZS",
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Eslatma: ${appointment.notes}",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isBarberView) ...[
                  // Customer Actions
                  if (appointment.canCancel) ...[
                    OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(80, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Bekor qilish", style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onReschedule,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        minimumSize: const Size(80, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Ko'chirish", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  if (appointment.canReview) ...[
                    ElevatedButton(
                      onPressed: onReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(100, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Baho berish ★", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ] else ...[
                  // Barber Actions
                  if (appointment.isPending) ...[
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(80, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Rad etish", style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(90, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Tasdiqlash", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (appointment.isConfirmed) ...[
                    ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(90, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Yakunlandi ✓", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
