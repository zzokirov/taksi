import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/barber_model.dart';

class BarberCard extends StatelessWidget {
  final BarberModel barber;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBook;

  const BarberCard({
    super.key,
    required this.barber,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barber Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: AppColors.card,
                      child: barber.avatar != null && barber.avatar!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: barber.avatar!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.gold, size: 36),
                            )
                          : const Icon(Icons.person, color: AppColors.gold, size: 36),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Barber Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                barber.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (barber.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: AppColors.gold, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          barber.barbershopName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              barber.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              " (${barber.ratingCount})",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const Spacer(),
                            if (barber.minPrice > 0)
                              Text(
                                "dan ${currencyFormatter.format(barber.minPrice)} UZS",
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      barber.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: barber.isFavorite ? Colors.redAccent : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: onFavoriteToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // Bottom Actions: address & book button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 15),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            barber.address ?? "Toshkent shahri",
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(110, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Yozilish",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
