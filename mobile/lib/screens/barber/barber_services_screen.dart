import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BarberServicesScreen extends ConsumerStatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  ConsumerState<BarberServicesScreen> createState() => _BarberServicesScreenState();
}

class _BarberServicesScreenState extends ConsumerState<BarberServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).fetchServices());
  }

  void _showAddEditServiceModal([ServiceModel? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(text: existing != null ? existing.price.toInt().toString() : '50000');
    final durationController = TextEditingController(text: existing != null ? existing.durationMinutes.toString() : '30');
    final descController = TextEditingController(text: existing?.description ?? '');
    bool isActive = existing?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing != null ? "Xizmatni tahrirlash" : "Yangi xizmat qo'shish",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nameController,
                label: "Xizmat nomi",
                hint: "Masalan: Skin Fade",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: priceController,
                      label: "Narxi (UZS)",
                      hint: "60000",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: durationController,
                      label: "Davomiyligi (daq.)",
                      hint: "30",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descController,
                label: "Tavsif (ixtiyoriy)",
                hint: "Xizmat haqida qo'shimcha ma'lumot...",
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Faol xizmat", style: TextStyle(color: Colors.white, fontSize: 14)),
                value: isActive,
                activeColor: AppColors.gold,
                onChanged: (v) => setModalState(() => isActive = v),
              ),
              const SizedBox(height: 18),
              CustomButton(
                text: "Saqlash",
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                  final duration = int.tryParse(durationController.text.trim()) ?? 30;

                  if (name.isEmpty) return;

                  final serviceModel = ServiceModel(
                    id: existing?.id ?? 0,
                    name: name,
                    description: descController.text.trim(),
                    price: price,
                    durationMinutes: duration,
                    isActive: isActive,
                  );

                  Navigator.of(ctx).pop();
                  if (existing != null) {
                    await ref.read(dashboardProvider.notifier).updateService(existing.id, serviceModel);
                  } else {
                    await ref.read(dashboardProvider.notifier).createService(serviceModel);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');
    final dashState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Xizmatlarim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _showAddEditServiceModal(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchServices();
        },
        child: dashState.services.isEmpty
            ? EmptyStateView(
                icon: Icons.content_cut,
                title: "Xizmatlar mavjud emas",
                subtitle: "Yangi xizmat qo'shish orqali mijozlarni jalb qiling.",
                buttonText: "Xizmat qo'shish",
                onButtonPressed: () => _showAddEditServiceModal(),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dashState.services.length,
                itemBuilder: (context, index) {
                  final service = dashState.services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.content_cut, color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "${currencyFormatter.format(service.price)} UZS",
                                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "• ${service.durationMinutes} daq.",
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.gold, size: 20),
                            onPressed: () => _showAddEditServiceModal(service),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text("Xizmatni o'chirish", style: TextStyle(color: Colors.white)),
                                  content: Text("${service.name} xizmatini o'chirmoqchimisiz?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Bekor qilish")),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text("O'chirish"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(dashboardProvider.notifier).deleteService(service.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Yangi xizmat", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditServiceModal(),
      ),
    );
  }
}
