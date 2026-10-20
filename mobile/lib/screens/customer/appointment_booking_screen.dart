import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../providers/barbers_provider.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/custom_button.dart';

class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final int barberId;
  final int? preselectedServiceId;

  const AppointmentBookingScreen({
    super.key,
    required this.barberId,
    this.preselectedServiceId,
  });

  @override
  ConsumerState<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends ConsumerState<AppointmentBookingScreen> {
  BarberModel? _barber;
  ServiceModel? _selectedService;
  late DateTime _selectedDate;
  String? _selectedTime;
  final _notesController = TextEditingController();
  bool _isLoadingBarber = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadBarberData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadBarberData() async {
    final b = await ref.read(barbersProvider.notifier).getBarberDetail(widget.barberId);
    if (mounted) {
      setState(() {
        _barber = b;
        _isLoadingBarber = false;
        if (b != null && b.services.isNotEmpty) {
          if (widget.preselectedServiceId != null) {
            _selectedService = b.services.firstWhere(
              (s) => s.id == widget.preselectedServiceId,
              orElse: () => b.services.first,
            );
          } else {
            _selectedService = b.services.first;
          }
        }
      });
      _loadSlots();
    }
  }

  void _loadSlots() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    ref.read(appointmentsProvider.notifier).fetchAvailableSlots(
      barberId: widget.barberId,
      date: dateStr,
      serviceId: _selectedService?.id,
    );
    setState(() => _selectedTime = null);
  }

  void _handleConfirmBooking() async {
    if (_selectedService == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, xizmat va qabul vaqtini tanlang!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await ref.read(appointmentsProvider.notifier).bookAppointment(
      barberId: widget.barberId,
      serviceId: _selectedService!.id,
      date: dateStr,
      timeStr: _selectedTime!,
      notes: _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      // Step 8: Display appointment confirmation and status dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text("Qabul belgilandi!", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sartarosh: ${_barber?.fullName}",
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text("Xizmat: ${_selectedService?.name}", style: const TextStyle(color: Colors.white)),
              Text("Sana va vaqt: $dateStr, soat $_selectedTime", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Holat: Kutilmoqda (Pending). Sartarosh tasdiqlaganida bildirishnoma keladi.",
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/customer?tab=appointments');
              },
              child: const Text("Qabullarimga o'tish"),
            ),
          ],
        ),
      );
    } else if (mounted) {
      final err = ref.read(appointmentsProvider).errorMessage ?? "Buyurtma berishda xatolik";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');
    final apptState = ref.watch(appointmentsProvider);

    if (_isLoadingBarber) {
      return const Scaffold(body: LoadingView(message: "Tayyorlanmoqda..."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vaqt Belgilash"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Barber Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.gold, size: 30),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _barber?.fullName ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _barber?.barbershopName ?? '',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step 2: Select Service
            const Text(
              "1. Xizmatni tanlang:",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_barber != null && _barber!.services.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _barber!.services.map((s) {
                  final isSelected = _selectedService?.id == s.id;
                  return ChoiceChip(
                    label: Text("${s.name} (${currencyFormatter.format(s.price)} UZS)"),
                    selected: isSelected,
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.gold : AppColors.cardBorder),
                    onSelected: (val) {
                      setState(() => _selectedService = s);
                      _loadSlots();
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Step 3: Select Date (Next 14 days calendar selector)
            const Text(
              "2. Sanani tanlang:",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  final dayName = DateFormat('E', 'uz').format(date);
                  final dayNum = DateFormat('d').format(date);

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadSlots();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Step 4 & 5: Load and Select Time Slot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "3. Qabul vaqtini tanlang:",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (apptState.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (!apptState.isLoading && apptState.availableSlots.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  "Tanlangan sanada bo'sh vaqtlar qolmagan yoki sartarosh dam olish kuni.",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: apptState.availableSlots.map((slot) {
                  final timeStr = slot['start_time']!;
                  final isSelected = _selectedTime == timeStr;

                  return InkWell(
                    onTap: () => setState(() => _selectedTime = timeStr),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Step 6: Notes (Optional)
            const Text(
              "4. Eslatma (ixtiyoriy):",
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Sartaroshga aytmoqchi bo'lgan maxsus istaklaringiz...",
              ),
            ),
            const SizedBox(height: 28),

            // Step 7: Booking Summary & Confirm Button
            if (_selectedService != null && _selectedTime != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Xizmat:", style: TextStyle(color: AppColors.textSecondary)),
                        Text(_selectedService!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Vaqt:", style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          "${DateFormat('dd.MM.yyyy').format(_selectedDate)} soat $_selectedTime",
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("To'lov summasi:", style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          "${currencyFormatter.format(_selectedService!.price)} UZS",
                          style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            CustomButton(
              text: "Buyurtmani tasdiqlash",
              isLoading: _isSubmitting,
              onPressed: _handleConfirmBooking,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
