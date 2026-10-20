import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state_view.dart';

class BarberAppointmentsScreen extends ConsumerStatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  ConsumerState<BarberAppointmentsScreen> createState() => _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState extends ConsumerState<BarberAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['today', 'pending', 'confirmed', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(appointmentsProvider.notifier).fetchBarberAppointments(
          tab: _tabs[_tabController.index],
        );
      }
    });

    Future.microtask(() {
      ref.read(appointmentsProvider.notifier).fetchBarberAppointments(tab: 'today');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apptState = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyurtmalar Boshqaruvi"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: "Bugun"),
            Tab(text: "Kutilmoqda"),
            Tab(text: "Tasdiqlangan"),
            Tab(text: "Bajarildi"),
            Tab(text: "Bekor"),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(appointmentsProvider.notifier).fetchBarberAppointments(
            tab: _tabs[_tabController.index],
          );
        },
        child: apptState.isLoading
            ? const LoadingView(message: "Buyurtmalar yuklanmoqda...")
            : apptState.barberAppointments.isEmpty
                ? const EmptyStateView(
                    icon: Icons.calendar_month_outlined,
                    title: "Ushbu bo'limda buyurtmalar yo'q",
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: apptState.barberAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = apptState.barberAppointments[index];
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
                            reason: "Sartarosh tomonidan rad etildi",
                          );
                        },
                        onComplete: () {
                          ref.read(appointmentsProvider.notifier).updateAppointmentStatus(
                            appointmentId: appt.id,
                            newStatus: 'completed',
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
