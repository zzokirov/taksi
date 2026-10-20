import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/service_model.dart';
import '../models/revenue_stats_model.dart';
import 'auth_provider.dart';

class BarberOverviewData {
  final int todayBookingsCount;
  final int pendingRequestsCount;
  final int confirmedAppointmentsCount;
  final int completedAppointmentsCount;
  final int todayRevenue;
  final int monthlyRevenue;
  final double ratingAvg;
  final int ratingCount;
  final bool isVerified;
  final String verificationStatus;

  BarberOverviewData({
    this.todayBookingsCount = 0,
    this.pendingRequestsCount = 0,
    this.confirmedAppointmentsCount = 0,
    this.completedAppointmentsCount = 0,
    this.todayRevenue = 0,
    this.monthlyRevenue = 0,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.isVerified = false,
    this.verificationStatus = 'pending',
  });

  factory BarberOverviewData.fromJson(Map<String, dynamic> json) {
    return BarberOverviewData(
      todayBookingsCount: json['today_bookings_count'] ?? 0,
      pendingRequestsCount: json['pending_requests_count'] ?? 0,
      confirmedAppointmentsCount: json['confirmed_appointments_count'] ?? 0,
      completedAppointmentsCount: json['completed_appointments_count'] ?? 0,
      todayRevenue: json['today_revenue'] ?? 0,
      monthlyRevenue: json['monthly_revenue'] ?? 0,
      ratingAvg: (json['rating_avg'] != null) ? (json['rating_avg'] as num).toDouble() : 0.0,
      ratingCount: json['rating_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      verificationStatus: json['verification_status'] ?? 'pending',
    );
  }
}

class DashboardState {
  final bool isLoading;
  final BarberOverviewData? overview;
  final List<ServiceModel> services;
  final List<dynamic> workingHours;
  final List<dynamic> customers;
  final RevenueStatsModel? revenueStats;
  final String? errorMessage;

  DashboardState({
    this.isLoading = false,
    this.overview,
    this.services = const [],
    this.workingHours = const [],
    this.customers = const [],
    this.revenueStats,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    BarberOverviewData? overview,
    List<ServiceModel>? services,
    List<dynamic>? workingHours,
    List<dynamic>? customers,
    RevenueStatsModel? revenueStats,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      overview: overview ?? this.overview,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      customers: customers ?? this.customers,
      revenueStats: revenueStats ?? this.revenueStats,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;

  DashboardNotifier(this._apiClient) : super(DashboardState());

  Future<void> fetchOverview() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberOverview);
      if (res.statusCode == 200) {
        final data = BarberOverviewData.fromJson(res.data);
        state = state.copyWith(isLoading: false, overview: data);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.formatError(e));
    }
  }

  Future<void> fetchServices() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberServices);
      if (res.statusCode == 200) {
        List<dynamic> list = [];
        if (res.data is Map && res.data.containsKey('results')) {
          list = res.data['results'];
        } else if (res.data is List) {
          list = res.data;
        }
        final services = list.map((e) => ServiceModel.fromJson(e)).toList();
        state = state.copyWith(services: services);
      }
    } catch (_) {}
  }

  Future<bool> createService(ServiceModel service) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.barberServices,
        data: service.toJson(),
      );
      if (res.statusCode == 201) {
        await fetchServices();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateService(int id, ServiceModel service) async {
    try {
      final res = await _apiClient.dio.put(
        '${ApiConstants.barberServices}$id/',
        data: service.toJson(),
      );
      if (res.statusCode == 200) {
        await fetchServices();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteService(int id) async {
    try {
      final res = await _apiClient.dio.delete('${ApiConstants.barberServices}$id/');
      if (res.statusCode == 204) {
        await fetchServices();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchWorkingHours() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberWorkingHours);
      if (res.statusCode == 200) {
        state = state.copyWith(workingHours: res.data as List);
      }
    } catch (_) {}
  }

  Future<bool> saveWorkingHours(List<dynamic> hoursList) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.barberWorkingHours,
        data: hoursList,
      );
      if (res.statusCode == 200) {
        state = state.copyWith(workingHours: res.data as List);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchCustomers() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberCustomers);
      if (res.statusCode == 200) {
        state = state.copyWith(customers: res.data as List);
      }
    } catch (_) {}
  }

  Future<void> fetchRevenueStats() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberRevenueStats);
      if (res.statusCode == 200) {
        final stats = RevenueStatsModel.fromJson(res.data);
        state = state.copyWith(revenueStats: stats);
      }
    } catch (_) {}
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardNotifier(client);
});
