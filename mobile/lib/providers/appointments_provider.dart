import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/appointment_model.dart';
import 'auth_provider.dart';

class AppointmentsState {
  final bool isLoading;
  final List<AppointmentModel> customerAppointments;
  final List<AppointmentModel> barberAppointments;
  final List<Map<String, String>> availableSlots;
  final String? errorMessage;
  final String currentTab;

  AppointmentsState({
    this.isLoading = false,
    this.customerAppointments = const [],
    this.barberAppointments = const [],
    this.availableSlots = const [],
    this.errorMessage,
    this.currentTab = 'upcoming',
  });

  AppointmentsState copyWith({
    bool? isLoading,
    List<AppointmentModel>? customerAppointments,
    List<AppointmentModel>? barberAppointments,
    List<Map<String, String>>? availableSlots,
    String? errorMessage,
    String? currentTab,
  }) {
    return AppointmentsState(
      isLoading: isLoading ?? this.isLoading,
      customerAppointments: customerAppointments ?? this.customerAppointments,
      barberAppointments: barberAppointments ?? this.barberAppointments,
      availableSlots: availableSlots ?? this.availableSlots,
      errorMessage: errorMessage,
      currentTab: currentTab ?? this.currentTab,
    );
  }
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final ApiClient _apiClient;

  AppointmentsNotifier(this._apiClient) : super(AppointmentsState());

  Future<void> fetchAvailableSlots({
    required int barberId,
    required String date,
    int? serviceId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, availableSlots: []);
    try {
      final res = await _apiClient.dio.get(
        ApiConstants.availableSlots,
        queryParameters: {
          'barber_id': barberId,
          'date': date,
          if (serviceId != null) 'service_id': serviceId,
        },
      );

      if (res.statusCode == 200) {
        final List rawSlots = res.data['available_slots'] ?? [];
        final slots = rawSlots.map((e) => {
          'start_time': e['start_time'].toString(),
          'end_time': e['end_time'].toString(),
        }).toList();

        state = state.copyWith(isLoading: false, availableSlots: slots);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
    }
  }

  Future<bool> bookAppointment({
    required int barberId,
    required int serviceId,
    required String date,
    required String timeStr,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.bookAppointment,
        data: {
          'barber_id': barberId,
          'service_id': serviceId,
          'appointment_date': date,
          'time_str': timeStr,
          'notes': notes ?? '',
        },
      );

      if (res.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        await fetchCustomerAppointments();
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
      return false;
    }
    return false;
  }

  Future<void> fetchCustomerAppointments({String? tab}) async {
    final activeTab = tab ?? state.currentTab;
    state = state.copyWith(isLoading: true, errorMessage: null, currentTab: activeTab);

    try {
      final res = await _apiClient.dio.get(
        ApiConstants.customerAppointments,
        queryParameters: {'status': activeTab},
      );

      if (res.statusCode == 200) {
        List<dynamic> results = [];
        if (res.data is Map && res.data.containsKey('results')) {
          results = res.data['results'];
        } else if (res.data is List) {
          results = res.data;
        }

        final list = results.map((e) => AppointmentModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, customerAppointments: list);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
    }
  }

  Future<void> fetchBarberAppointments({String? tab}) async {
    final activeTab = tab ?? 'today';
    state = state.copyWith(isLoading: true, errorMessage: null, currentTab: activeTab);

    try {
      final res = await _apiClient.dio.get(
        ApiConstants.barberAppointments,
        queryParameters: {'status': activeTab},
      );

      if (res.statusCode == 200) {
        List<dynamic> results = [];
        if (res.data is Map && res.data.containsKey('results')) {
          results = res.data['results'];
        } else if (res.data is List) {
          results = res.data;
        }

        final list = results.map((e) => AppointmentModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, barberAppointments: list);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
    }
  }

  Future<bool> updateAppointmentStatus({
    required int appointmentId,
    required String newStatus,
    String? reason,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.appointmentStatus(appointmentId),
        data: {'status': newStatus, 'reason': reason ?? ''},
      );
      if (res.statusCode == 200) {
        await fetchBarberAppointments(tab: state.currentTab);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> cancelAppointment(int appointmentId, String reason) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.appointmentCancel(appointmentId),
        data: {'reason': reason},
      );
      if (res.statusCode == 200) {
        await fetchCustomerAppointments();
        await fetchBarberAppointments();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> rescheduleAppointment(int appointmentId, String newDate, String newTime) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.appointmentReschedule(appointmentId),
        data: {
          'new_date': newDate,
          'new_time_str': newTime,
        },
      );
      if (res.statusCode == 200) {
        await fetchCustomerAppointments();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> submitReview({
    required int appointmentId,
    required int rating,
    required String comment,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.reviews,
        data: {
          'appointment_id': appointmentId,
          'rating': rating,
          'comment': comment,
        },
      );
      if (res.statusCode == 201) {
        await fetchCustomerAppointments();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final appointmentsProvider = StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AppointmentsNotifier(client);
});
