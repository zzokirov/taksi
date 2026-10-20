import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final res = await _apiClient.dio.get(ApiConstants.currentUser);
      if (res.statusCode == 200) {
        final user = UserModel.fromJson(res.data);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        await TokenStorage.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // In case of network glitch but token exists, check role from local storage
      final role = await TokenStorage.getUserRole();
      final id = await TokenStorage.getUserId();
      if (role != null && id != null) {
        final fallbackUser = UserModel(
          id: id,
          phoneNumber: '',
          fullName: 'Foydalanuvchi',
          role: role,
        );
        state = state.copyWith(status: AuthStatus.authenticated, user: fallbackUser);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiClient.dio.post(ApiConstants.login, data: {
        'phone_number': phone.trim(),
        'password': password,
      });

      if (res.statusCode == 200) {
        final access = res.data['access'];
        final refresh = res.data['refresh'];
        final userData = res.data['user'];
        final user = UserModel.fromJson(userData);

        await TokenStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
          role: user.role,
          userId: user.id,
        );

        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      }
    } catch (e) {
      final msg = ApiClient.formatError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
    return false;
  }

  Future<bool> registerCustomer({
    required String phone,
    required String fullName,
    required String password,
    required String passwordConfirm,
    String? email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiClient.dio.post(ApiConstants.registerCustomer, data: {
        'phone_number': phone.trim(),
        'full_name': fullName.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
        'email': email,
        'terms_accepted': true,
      });

      if (res.statusCode == 201) {
        final access = res.data['access'];
        final refresh = res.data['refresh'];
        final user = UserModel.fromJson(res.data['user']);

        await TokenStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
          role: user.role,
          userId: user.id,
        );

        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      }
    } catch (e) {
      final msg = ApiClient.formatError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
    return false;
  }

  Future<bool> registerBarber({
    required String phone,
    required String fullName,
    required String password,
    required String passwordConfirm,
    required String barbershopName,
    required String address,
    required String bio,
    required int experienceYears,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _apiClient.dio.post(ApiConstants.registerBarber, data: {
        'phone_number': phone.trim(),
        'full_name': fullName.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
        'barbershop_name': barbershopName.trim(),
        'address': address.trim(),
        'bio': bio.trim(),
        'experience_years': experienceYears,
      });

      if (res.statusCode == 201) {
        final access = res.data['access'];
        final refresh = res.data['refresh'];
        final user = UserModel.fromJson(res.data['user']);

        await TokenStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
          role: user.role,
          userId: user.id,
        );

        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      }
    } catch (e) {
      final msg = ApiClient.formatError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
    return false;
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
