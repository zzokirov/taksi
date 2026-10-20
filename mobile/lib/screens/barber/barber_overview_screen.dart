import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/appointment_card.dart';

class BarberOverviewScreen extends ConsumerStatefulWidget {
  const BarberOverviewScreen({super.key});

  @override
  ConsumerState<BarberOverviewScreen> createState() => _BarberOverviewScreenState();
}

class _BarberOverviewScreenState extends ConsumerState<BarberOverviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).fetchOverview();
      ref.read(appointmentsProvider.notifier).fetchBarberAppointments(tab: 'today');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');
    final user = ref.watch(authProvider).user;
    final dashState = ref.watch(dashboardProvider);
    final apptState = ref.watch(appointmentsProvider);
    final overview = dashState.overview;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sartarosh Kabineti"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchOverview();
          await ref.read(appointmentsProvider.notifier).fetchBarberAppointments(tab: 'today');
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification Warning Banner if Pending
              if (overview != null && !overview.isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, color: AppColors.warning, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Akkauntingiz tekshirilmoqda. Administrator tasdiqlaganidan so'ng yangi mijozlar sizga yozilishlari mumkin bo'ladi.",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Barber Greeting Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.person, color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? "Usta",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.gold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${overview?.ratingAvg.toStringAsFixed(1) ?? '5.0'} (${overview?.ratingCount ?? 0} baho)",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Statistics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Bugungi tushum",
                      value: "${currencyFormatter.format(overview?.todayRevenue ?? 0)} UZS",
                      icon: Icons.payments_outlined,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: "Oylik tushum",
                      value: "${currencyFormatter.format(overview?.monthlyRevenue ?? 0)} UZS",
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Yangi so'rovlar",
                      value: "${overview?.pendingRequestsCount ?? 0} ta",
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: "Bugungi qabullar",
                      value: "${overview?.todayBookingsCount ?? 0} ta",
                      icon: Icons.event_available,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Appointments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bugungi Qabullar Jadvali",
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(DateTime.now()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (apptState.isLoading) ...[
                const LoadingView(message: "Qabullar yuklanmoqda..."),
              ] else if (apptState.barberAppointments.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_note, color: AppColors.textMuted, size: 40),
                      SizedBox(height: 10),
                      Text(
                        "Bugun uchun hali qabullar yo'q",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...apptState.barberAppointments.map((appt) {
                  return AppointmentCard(
                    appointment: appt,
                    isBarberView: true,
                    onConfirm: () {
                      ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
                        appointmentId: appt.id,
                        newStatus: 'confirmed',
                      );
                    },
                    onReject: () {
                      ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
                        appointmentId: appt.id,
                        newStatus: 'cancelled',
                        reason: "Vaqt band yoki sartarosh qabul qila olmaydi",
                      );
                    },
                    onComplete: () {
                      ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
                        appointmentId: appt.id,
                        newStatus: 'completed',
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
