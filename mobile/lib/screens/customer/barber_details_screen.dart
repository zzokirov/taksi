import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../providers/barbers_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/custom_button.dart';

class BarberDetailsScreen extends ConsumerStatefulWidget {
  final int barberId;

  const BarberDetailsScreen({super.key, required this.barberId});

  @override
  ConsumerState<BarberDetailsScreen> createState() => _BarberDetailsScreenState();
}

class _BarberDetailsScreenState extends ConsumerState<BarberDetailsScreen> {
  BarberModel? _barber;
  bool _isLoading = true;
  ServiceModel? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadBarber();
  }

  void _loadBarber() async {
    final b = await ref.read(barbersProvider.notifier).getBarberDetail(widget.barberId);
    if (mounted) {
      setState(() {
        _barber = b;
        _isLoading = false;
        if (b != null && b.services.isNotEmpty) {
          _selectedService = b.services.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');

    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: "Sartarosh ma'lumotlari yuklanmoqda..."));
    }

    if (_barber == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Sartarosh topilmadi")),
      );
    }

    final barber = _barber!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: barber.avatar != null && barber.avatar!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: barber.avatar!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.person, color: AppColors.gold, size: 80),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person, color: AppColors.gold, size: 80),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  barber.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: barber.isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: () async {
                  final isFav = await ref.read(barbersProvider.notifier).toggleFavorite(barber.id);
                  setState(() {
                    _barber = barber.copyWith(isFavorite: isFav);
                  });
                },
              ),
            ],
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Verification
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          barber.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (barber.isVerified) ...[
                        const Icon(Icons.verified, color: AppColors.gold, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Barbershop
                  Text(
                    barber.barbershopName,
                    style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Rating & Experience
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        barber.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        " (${barber.ratingCount} baho)",
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.work_history_outlined, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${barber.experienceYears} yil tajriba",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          barber.address ?? "Toshkent shahri",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (barber.bio != null && barber.bio!.isNotEmpty) ...[
                    const Text("Haqida", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      barber.bio!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Services Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Xizmatlar va Narxlar",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${barber.services.length} ta xizmat",
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Services List
                  if (barber.services.isEmpty) ...[
                    const Text(
                      "Hozircha xizmatlar qo'shilmagan",
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ] else ...[
                    ...barber.services.map((service) {
                      final isSelected = _selectedService?.id == service.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.gold : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: service.id,
                          groupValue: _selectedService?.id,
                          activeColor: AppColors.gold,
                          onChanged: (_) {
                            setState(() => _selectedService = service);
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                "${currencyFormatter.format(service.price)} UZS",
                                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "${service.durationMinutes} daqiqa",
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                if (service.description.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "• ${service.description}",
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 80), // Padding for bottom floating bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_selectedService != null) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Jami narx:", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      "${currencyFormatter.format(_selectedService!.price)} UZS",
                      style: const TextStyle(color: AppColors.gold, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: CustomButton(
                  text: "Vaqt belgilash",
                  icon: Icons.calendar_today,
                  onPressed: () {
                    context.push('/book/${barber.id}?service_id=${_selectedService?.id ?? ""}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
