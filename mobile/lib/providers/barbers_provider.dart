import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/barber_model.dart';
import 'auth_provider.dart';

class BarbersState {
  final bool isLoading;
  final List<BarberModel> barbers;
  final List<BarberModel> favoriteBarbers;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedService;
  final double? minRating;

  BarbersState({
    this.isLoading = false,
    this.barbers = const [],
    this.favoriteBarbers = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedService,
    this.minRating,
  });

  BarbersState copyWith({
    bool? isLoading,
    List<BarberModel>? barbers,
    List<BarberModel>? favoriteBarbers,
    String? errorMessage,
    String? searchQuery,
    String? selectedService,
    double? minRating,
  }) {
    return BarbersState(
      isLoading: isLoading ?? this.isLoading,
      barbers: barbers ?? this.barbers,
      favoriteBarbers: favoriteBarbers ?? this.favoriteBarbers,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedService: selectedService ?? this.selectedService,
      minRating: minRating ?? this.minRating,
    );
  }
}

class BarbersNotifier extends StateNotifier<BarbersState> {
  final ApiClient _apiClient;

  BarbersNotifier(this._apiClient) : super(BarbersState()) {
    fetchBarbers();
  }

  Future<void> fetchBarbers({String? search, String? service, double? rating}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      searchQuery: search ?? state.searchQuery,
      selectedService: service ?? state.selectedService,
      minRating: rating ?? state.minRating,
    );

    try {
      final queryParams = <String, dynamic>{};
      if (state.searchQuery.isNotEmpty) queryParams['search'] = state.searchQuery;
      if (state.selectedService != null && state.selectedService!.isNotEmpty) {
        queryParams['service'] = state.selectedService;
      }
      if (state.minRating != null) queryParams['min_rating'] = state.minRating;

      final res = await _apiClient.dio.get(
        ApiConstants.barbers,
        queryParameters: queryParams,
      );

      if (res.statusCode == 200) {
        List<dynamic> results = [];
        if (res.data is Map && res.data.containsKey('results')) {
          results = res.data['results'];
        } else if (res.data is List) {
          results = res.data;
        }

        final list = results.map((e) => BarberModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, barbers: list);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
    }
  }

  Future<BarberModel?> getBarberDetail(int barberId) async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.barberDetail(barberId));
      if (res.statusCode == 200) {
        return BarberModel.fromJson(res.data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> fetchFavorites() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.favorites);
      if (res.statusCode == 200) {
        List<dynamic> results = [];
        if (res.data is Map && res.data.containsKey('results')) {
          results = res.data['results'];
        } else if (res.data is List) {
          results = res.data;
        }

        final list = results
            .where((e) => e['barber_detail'] != null)
            .map((e) => BarberModel.fromJson(e['barber_detail']))
            .toList();

        state = state.copyWith(favoriteBarbers: list);
      }
    } catch (_) {}
  }

  Future<bool> toggleFavorite(int barberId) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.favoriteToggle,
        data: {'barber_id': barberId},
      );

      if (res.statusCode == 200) {
        final bool isFav = res.data['favorited'] ?? false;
        
        // Update local state list
        final updated = state.barbers.map((b) {
          if (b.id == barberId) {
            return b.copyWith(isFavorite: isFav);
          }
          return b;
        }).toList();

        state = state.copyWith(barbers: updated);
        await fetchFavorites();
        return isFav;
      }
    } catch (_) {}
    return false;
  }
}

final barbersProvider = StateNotifierProvider<BarbersNotifier, BarbersState>((ref) {
  final client = ref.watch(apiClientProvider);
  return BarbersNotifier(client);
});
