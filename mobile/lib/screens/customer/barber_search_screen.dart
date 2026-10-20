import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/barbers_provider.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state_view.dart';

class BarberSearchScreen extends ConsumerStatefulWidget {
  const BarberSearchScreen({super.key});

  @override
  ConsumerState<BarberSearchScreen> createState() => _BarberSearchScreenState();
}

class _BarberSearchScreenState extends ConsumerState<BarberSearchScreen> {
  final _searchController = TextEditingController();
  double? _minRating;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(barbersProvider.notifier).fetchBarbers(
      search: _searchController.text.trim(),
      rating: _minRating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final barbersState = ref.watch(barbersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sartarosh Qidirish"),
      ),
      body: Column(
        children: [
          // Search Input & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _triggerSearch(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Sartarosh yoki salon nomi...",
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _triggerSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Rating filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text("Reyting: ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Barchasi"),
                  selected: _minRating == null,
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _minRating == null ? Colors.black : Colors.white70,
                    fontSize: 12,
                  ),
                  onSelected: (v) {
                    setState(() => _minRating = null);
                    _triggerSearch();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("4.5+ ★"),
                  selected: _minRating == 4.5,
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _minRating == 4.5 ? Colors.black : Colors.white70,
                    fontSize: 12,
                  ),
                  onSelected: (v) {
                    setState(() => _minRating = 4.5);
                    _triggerSearch();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("4.8+ ★"),
                  selected: _minRating == 4.8,
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _minRating == 4.8 ? Colors.black : Colors.white70,
                    fontSize: 12,
                  ),
                  onSelected: (v) {
                    setState(() => _minRating = 4.8);
                    _triggerSearch();
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 16),

          // Search Results List
          Expanded(
            child: barbersState.isLoading
                ? const LoadingView(message: "Qidirilmoqda...")
                : barbersState.barbers.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.search_off,
                        title: "Sartaroshlar topilmadi",
                        subtitle: "Boshqa qidiruv so'zi yoki filtrlardan foydalanib ko'ring.",
                      )
                    : ListView.builder(
                        itemCount: barbersState.barbers.length,
                        itemBuilder: (context, index) {
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
                      ),
          ),
        ],
      ),
    );
  }
}
