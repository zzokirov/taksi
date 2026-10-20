import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/custom_button.dart';

class BarberScheduleScreen extends ConsumerStatefulWidget {
  const BarberScheduleScreen({super.key});

  @override
  ConsumerState<BarberScheduleScreen> createState() => _BarberScheduleScreenState();
}

class _BarberScheduleScreenState extends ConsumerState<BarberScheduleScreen> {
  final List<String> _dayNames = [
    "Dushanba",
    "Seshanba",
    "Chorshanba",
    "Payshanba",
    "Juma",
    "Shanba",
    "Yakshanba"
  ];

  late List<Map<String, dynamic>> _scheduleData;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadSchedule());
  }

  void _loadSchedule() async {
    await ref.read(dashboardProvider.notifier).fetchWorkingHours();
    final raw = ref.read(dashboardProvider).workingHours;

    if (raw.isNotEmpty) {
      _scheduleData = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _scheduleData = List.generate(7, (i) => {
        'day_of_week': i,
        'day_name': _dayNames[i],
        'is_working_day': i < 6,
        'start_time': '09:00:00',
        'end_time': '19:00:00',
      });
    }

    if (mounted) setState(() => _isInitialized = true);
  }

  void _saveSchedule() async {
    setState(() => _isSaving = true);
    final success = await ref.read(dashboardProvider.notifier).saveWorkingHours(_scheduleData);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ish jadvali muvaffaqiyatli saqlandi!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: LoadingView(message: "Jadval yuklanmoqda..."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ish Jadvali & Vaqtlar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.gold),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduleData.length,
        itemBuilder: (context, index) {
          final item = _scheduleData[index];
          final dayNum = item['day_of_week'] as int;
          final dayName = _dayNames[dayNum];
          final bool isWorking = item['is_working_day'] ?? true;
          final startTime = item['start_time'].toString().substring(0, 5);
          final endTime = item['end_time'].toString().substring(0, 5);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isWorking ? AppColors.gold.withOpacity(0.4) : AppColors.cardBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isWorking ? Colors.white : AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isWorking ? "Ish kuni" : "Dam olish",
                            style: TextStyle(
                              color: isWorking ? AppColors.gold : AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Switch(
                            value: isWorking,
                            activeColor: AppColors.gold,
                            onChanged: (val) {
                              setState(() {
                                item['is_working_day'] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isWorking) ...[
                    const Divider(color: AppColors.divider, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny_outlined, color: AppColors.gold, size: 16),
                            const SizedBox(width: 6),
                            const Text("Boshlanish: ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text(startTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Text("—", style: TextStyle(color: AppColors.textMuted)),
                        Row(
                          children: [
                            const Icon(Icons.nightlight_outlined, color: AppColors.gold, size: 16),
                            const SizedBox(width: 6),
                            const Text("Tugash: ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text(endTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: CustomButton(
            text: "O'zgarishlarni saqlash",
            isLoading: _isSaving,
            onPressed: _saveSchedule,
          ),
        ),
      ),
    );
  }
}
