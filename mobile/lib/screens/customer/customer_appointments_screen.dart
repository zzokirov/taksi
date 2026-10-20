import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state_view.dart';
import 'review_submit_modal.dart';

class CustomerAppointmentsScreen extends ConsumerStatefulWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  ConsumerState<CustomerAppointmentsScreen> createState() => _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState extends ConsumerState<CustomerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['upcoming', 'pending', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(appointmentsProvider.notifier).fetchCustomerAppointments(
          tab: _tabs[_tabController.index],
        );
      }
    });

    Future.microtask(() {
      ref.read(appointmentsProvider.notifier).fetchCustomerAppointments(tab: 'upcoming');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(AppointmentModel appt) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Buyurtmani bekor qilish", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Haqiqatan ham qabulni bekor qilmoqchimisiz? Sababini kiriting:",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: "Bekor qilish sababi..."),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Ortga", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(appointmentsProvider.notifier).cancelAppointment(
                appt.id,
                reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : "Mijoz tomonidan bekor qilindi",
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Qabul bekor qilindi"), backgroundColor: AppColors.warning),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Bekor qilish"),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(AppointmentModel appt) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = "14:00";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Vaqtni ko'chirish", style: TextStyle(color: AppColors.gold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yangi sanani tanlang: ${DateFormat('dd.MM.yyyy').format(selectedDate)}",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text("Boshqa sana tanlash"),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.card, foregroundColor: Colors.white),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text("Yangi soatni tanlang:", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ["10:00", "12:00", "14:00", "16:00", "18:00"].map((t) {
                  final isSel = selectedTime == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSel,
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white),
                    onSelected: (_) => setDialogState(() => selectedTime = t),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Bekor qilish", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                final success = await ref.read(appointmentsProvider.notifier).rescheduleAppointment(
                  appt.id,
                  dateStr,
                  selectedTime,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ko'chirish so'rovi yuborildi!"), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text("Ko'chirish"),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewModal(AppointmentModel appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewSubmitModal(
        appointmentId: appt.id,
        barberName: appt.barberName,
        onSubmit: (rating, comment) => ref.read(appointmentsProvider.notifier).submitReview(
          appointmentId: appt.id,
          rating: rating,
          comment: comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptState = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mening Qabullarim"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Kelgusi"),
            Tab(text: "Kutilmoqda"),
            Tab(text: "Bajarildi"),
            Tab(text: "Bekor"),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(appointmentsProvider.notifier).fetchCustomerAppointments(
            tab: _tabs[_tabController.index],
          );
        },
        child: apptState.isLoading
            ? const LoadingView(message: "Qabullar yuklanmoqda...")
            : apptState.customerAppointments.isEmpty
                ? const EmptyStateView(
                    icon: Icons.calendar_today_outlined,
                    title: "Ushbu bo'limda qabullar yo'q",
                    subtitle: "Sartaroshlarga yozilish orqali navbat oling.",
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: apptState.customerAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = apptState.customerAppointments[index];
                      return AppointmentCard(
                        appointment: appt,
                        isBarberView: false,
                        onCancel: () => _showCancelDialog(appt),
                        onReschedule: () => _showRescheduleDialog(appt),
                        onReview: () => _showReviewModal(appt),
                      );
                    },
                  ),
      ),
    );
  }
}
