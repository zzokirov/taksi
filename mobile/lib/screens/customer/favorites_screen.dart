import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/barbers_provider.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/empty_state_view.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(barbersProvider.notifier).fetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final barbersState = ref.watch(barbersProvider);
    final favorites = barbersState.favoriteBarbers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sevimli Sartaroshlar"),
      ),
      body: favorites.isEmpty
          ? EmptyStateView(
              icon: Icons.favorite_border,
              title: "Sevimlilar bo'sh",
              subtitle: "O'zingizga yoqqan sartaroshlarni yurakcha tugmasi orqali saqlab qo'ying.",
              buttonText: "Sartaroshlarni ko'rish",
              onButtonPressed: () => context.push('/search'),
            )
          : RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await ref.read(barbersProvider.notifier).fetchFavorites();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final barber = favorites[index];
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
    );
  }
}
