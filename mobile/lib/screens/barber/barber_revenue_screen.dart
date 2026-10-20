import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_view.dart';

class BarberRevenueScreen extends ConsumerStatefulWidget {
  const BarberRevenueScreen({super.key});

  @override
  ConsumerState<BarberRevenueScreen> createState() => _BarberRevenueScreenState();
}

class _BarberRevenueScreenState extends ConsumerState<BarberRevenueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).fetchRevenueStats());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'uz');
    final dashState = ref.watch(dashboardProvider);
    final stats = dashState.revenueStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daromad va Statistika"),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchRevenueStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Earned Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C2411), Color(0xFF1E1A11)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.goldDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jami Bajarilgan Daromad",
                      style: TextStyle(color: AppColors.goldLight, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${currencyFormatter.format(stats?.totalRevenue ?? 0)} UZS",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${stats?.totalCompleted ?? 0} ta bajarildi",
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${stats?.totalCancelled ?? 0} ta bekor",
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart: Daily Breakdown
              const Text(
                "Haftalik Daromad Grafigi",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: (stats == null || stats.dailyBreakdown.isEmpty)
                    ? const Center(child: Text("Ma'lumotlar yo'q", style: TextStyle(color: AppColors.textMuted)))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxRevenue(stats.dailyBreakdown),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.card,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final item = stats.dailyBreakdown[groupIndex];
                                return BarTooltipItem(
                                  "${item.dayName}\n${currencyFormatter.format(item.revenue)} UZS",
                                  const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < stats.dailyBreakdown.length) {
                                    return Text(
                                      stats.dailyBreakdown[idx].dayName,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: stats.dailyBreakdown.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.revenue,
                                  color: AppColors.gold,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Popular Services
              const Text(
                "Eng Talabgir Xizmatlar",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (stats == null || stats.popularServices.isEmpty) ...[
                const Text("Hozircha xizmatlar statistikasi yo'q", style: TextStyle(color: AppColors.textMuted)),
              ] else ...[
                ...stats.popularServices.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.serviceName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${p.count} marta bajarildi",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          "${currencyFormatter.format(p.revenue)} UZS",
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxRevenue(List<dynamic> list) {
    double m = 100000;
    for (var i in list) {
      if (i.revenue > m) m = i.revenue;
    }
    return m * 1.2;
  }
}
