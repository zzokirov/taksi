import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized by attempting Refresh Token
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/login')) {
      final refresh = await TokenStorage.getRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
          final res = await refreshDio.post(
            ApiConstants.refreshToken,
            data: {'refresh': refresh},
          );

          if (res.statusCode == 200 && res.data['access'] != null) {
            final newAccess = res.data['access'] as String;
            await TokenStorage.updateAccessToken(newAccess);

            // Retry original request with new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        } catch (_) {
          // Token refresh failed - session expired
          await TokenStorage.clearAll();
        }
      }
    }
    return handler.next(err);
  }
}
