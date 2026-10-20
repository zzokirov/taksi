import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barbers_provider.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final List<String> _services = [
    "Barchasi",
    "Klassik Soch",
    "Skin Fade",
    "Soqol Tekislash",
    "VIP Kompleks",
    "Bolalar sochi"
  ];
  String _selectedService = "Barchasi";

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(barbersProvider.notifier).fetchBarbers());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final barbersState = ref.watch(barbersProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(barbersProvider.notifier).fetchBarbers();
          },
          child: CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Salom,",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            user?.fullName ?? "Hurmatli Mijoz",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.notifications_none, color: AppColors.gold, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar Clickable Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () => context.push('/search'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.gold, size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Sartarosh yoki xizmat qidirish...",
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                          Spacer(),
                          Icon(Icons.tune, color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Promo Luxury Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C2411), Color(0xFF1E1A11)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.goldDark, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Premium Qulaylik",
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Navbatsiz, qulay vaqtda, eng tajribali ustalarga yoziling.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.push('/search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(110, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text("Boshlash", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.content_cut, color: AppColors.gold, size: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // Category Service Chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      final isSelected = s == _selectedService;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.gold : AppColors.cardBorder,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedService = s);
                          final query = (s == "Barchasi") ? "" : s;
                          ref.read(barbersProvider.notifier).fetchBarbers(service: query);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Title: Eng Sara Sartaroshlar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Eng Sara Sartaroshlar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/search'),
                        child: const Text("Barchasi >", style: TextStyle(color: AppColors.gold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              // Barbers List
              if (barbersState.isLoading) ...[
                const SliverFillRemaining(
                  child: LoadingView(message: "Sartaroshlar yuklanmoqda..."),
                ),
              ] else if (barbersState.errorMessage != null) ...[
                SliverFillRemaining(
                  child: ErrorView(
                    message: barbersState.errorMessage!,
                    onRetry: () => ref.read(barbersProvider.notifier).fetchBarbers(),
                  ),
                ),
              ] else if (barbersState.barbers.isEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        "Ushbu toifada sartaroshlar topilmadi",
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final barber = barbersState.barbers[index];
                      return BarberCard(
                        barber: barber,
                        onTap: () => context.push('/barber/${barber.id}'),
                        onFavoriteToggle: () {
                          ref.read(barbersProvider.notifier).toggleFavorite(barber.id);
                        },
                        onBook: () => context.push('/book/${barber.id}'),
                      );
                    },
                    childCount: barbersState.barbers.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
