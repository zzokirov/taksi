class RevenueStatsModel {
  final int totalRevenue;
  final int totalCompleted;
  final int totalCancelled;
  final List<DailyStatItem> dailyBreakdown;
  final List<PopularServiceItem> popularServices;

  RevenueStatsModel({
    required this.totalRevenue,
    required this.totalCompleted,
    required this.totalCancelled,
    required this.dailyBreakdown,
    required this.popularServices,
  });

  factory RevenueStatsModel.fromJson(Map<String, dynamic> json) {
    var rawDaily = json['daily_breakdown'] as List? ?? [];
    var rawPop = json['popular_services'] as List? ?? [];

    return RevenueStatsModel(
      totalRevenue: json['total_revenue'] ?? 0,
      totalCompleted: json['total_completed'] ?? 0,
      totalCancelled: json['total_cancelled'] ?? 0,
      dailyBreakdown: rawDaily.map((e) => DailyStatItem.fromJson(e)).toList(),
      popularServices: rawPop.map((e) => PopularServiceItem.fromJson(e)).toList(),
    );
  }
}

class DailyStatItem {
  final String date;
  final String dayName;
  final double revenue;
  final int count;

  DailyStatItem({
    required this.date,
    required this.dayName,
    required this.revenue,
    required this.count,
  });

  factory DailyStatItem.fromJson(Map<String, dynamic> json) {
    return DailyStatItem(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      revenue: (json['revenue'] != null) ? (json['revenue'] as num).toDouble() : 0.0,
      count: json['count'] ?? 0,
    );
  }
}

class PopularServiceItem {
  final String serviceName;
  final int count;
  final double revenue;

  PopularServiceItem({
    required this.serviceName,
    required this.count,
    required this.revenue,
  });

  factory PopularServiceItem.fromJson(Map<String, dynamic> json) {
    return PopularServiceItem(
      serviceName: json['service_name'] ?? '',
      count: json['count'] ?? 0,
      revenue: (json['revenue'] != null) ? (json['revenue'] as num).toDouble() : 0.0,
    );
  }
}
