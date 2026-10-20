import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({String? customBaseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          // Can be enabled in debug mode
        },
      ),
    );
  }

  // Friendly error extractor
  static String formatError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return "Server bilan bog'lanib bo'lmadi. Internet aloqasi yoki backend serverni tekshiring.";
      }

      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data.containsKey('detail')) {
            return data['detail'].toString();
          }
          if (data.containsKey('error')) {
            return data['error'].toString();
          }
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
          // Join first error list
          final values = data.values;
          if (values.isNotEmpty) {
            final first = values.first;
            if (first is List && first.isNotEmpty) {
              return first.first.toString();
            }
            return first.toString();
          }
        }
        return "Server xatosi: ${error.response?.statusCode}";
      }
      return error.message ?? "Noma'lum tarmoq xatosi";
    }
    return error.toString();
  }
}
