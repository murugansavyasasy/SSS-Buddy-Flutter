import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sssbuddy/repository/app_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewModel/login_view_model.dart';

class DioClient {
  late final Dio _vimsClient;
  late final Dio _schoolClient;
  late final Dio _awsClient;
  late final Dio _s3Client;

  final Ref ref;

  DioClient(this.ref) {
    _vimsClient = _buildDio(AppUrl.vimsUrl);
    _schoolClient = _buildDio(AppUrl.schoolUrl);
    _awsClient = _buildDio(AppUrl.aws_url);
    _s3Client = _buildDio('');
  }

  Dio get dio => _vimsClient;
  Dio get schoolDio => _schoolClient;
  Dio get awsDio => _awsClient;
  Dio get s3Dio => _s3Client;

  Dio _buildDio(String baseurl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseurl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),

        // Important:
        // Dio will throw DioException for 4xx/5xx.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          final exception = _handleDioError(error);

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: exception,
              message: exception.message,
            ),
          );
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );

    return dio;
  }

  // MARK: - Error Handler

  ApiException _handleDioError(DioException error) {
    final response = error.response;

    // API response body
    final data = response?.data;

    String? message;

    if (data is Map<String, dynamic>) {
      message = _extractMessageFromMap(data);
    } else if (data is Map) {
      message = _extractMessageFromMap(
        Map<String, dynamic>.from(data),
      );
    } else if (data is String && data.trim().isNotEmpty) {
      message = _extractMessageFromString(data);
    }

    // If backend returned a message, use it.
    if (message != null && message.trim().isNotEmpty) {
      return ApiException(
        message.trim(),
        statusCode: response?.statusCode,
      );
    }

    // Network / Dio errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          "Connection timed out. Please try again.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.sendTimeout:
        return ApiException(
          "Request timed out. Please try again.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          "Server response timed out. Please try again.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          "No internet connection. Please check your network.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          "Secure connection failed.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ApiException(
          "Request was cancelled.",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return ApiException(
          _statusCodeMessage(response?.statusCode),
          statusCode: response?.statusCode,
        );

      case DioExceptionType.unknown:
        return ApiException(
          "Something went wrong. Please try again.",
          statusCode: response?.statusCode,
        );
    }
  }

  String? _extractMessageFromMap(Map<String, dynamic> data) {
    // Common API formats

    if (data['message'] != null) {
      return data['message'].toString();
    }

    if (data['Message'] != null) {
      return data['Message'].toString();
    }

    if (data['error'] != null) {
      if (data['error'] is String) {
        return data['error'].toString();
      }

      if (data['error'] is Map) {
        final error = Map<String, dynamic>.from(data['error']);

        if (error['message'] != null) {
          return error['message'].toString();
        }
      }
    }

    if (data['Error'] != null) {
      return data['Error'].toString();
    }

    // Example:
    // {
    //   "status": "error",
    //   "errors": ["Invalid customer"]
    // }

    if (data['errors'] != null) {
      final errors = data['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors.join(', ');
      }

      if (errors is String) {
        return errors;
      }

      if (errors is Map) {
        return errors.values
            .expand(
              (value) => value is List
              ? value
              : [value],
        )
            .join(', ');
      }
    }

    return null;
  }

  String? _extractMessageFromString(String data) {
    try {
      final decoded = jsonDecode(data);

      if (decoded is Map) {
        return _extractMessageFromMap(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // Not JSON.
    }

    return data;
  }

  String _statusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return "Invalid request.";

      case 401:
        return "Unauthorized. Please login again.";

      case 403:
        return "You don't have permission to perform this action.";

      case 404:
        return "Requested resource was not found.";

      case 409:
        return "Request conflicts with existing data.";

      case 422:
        return "Invalid data provided.";

      case 429:
        return "Too many requests. Please try again later.";

      case 500:
        return "Server error. Please try again later.";

      case 502:
      case 503:
      case 504:
        return "Server is temporarily unavailable.";

      default:
        return "Something went wrong. Please try again.";
    }
  }

  // MARK: - VIMS GET

  Future<Response> get(
      String path, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? headers,
      }) async {
    try {
      return await _vimsClient.get(
        path,
        queryParameters: query,
        options: Options(
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }

  // MARK: - VIMS POST

  Future<Response> post(
      String path, {
        Object? body,
      }) async {
    try {
      final token = await getToken();

      return await _vimsClient.post(
        path,
        data: body,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }

  // MARK: - Token

  Future<String?> getToken() async {
    final loginState = ref.read(loginProvider);

    final loginData = loginState.value;

    if (loginData == null) {
      return null;
    }

    return loginData.token;
  }

  // MARK: - School POST

  Future<Response> schoolPost(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    try {
      return await _schoolClient.post(
        path,
        data: body,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }

  // MARK: - School GET

  Future<Response> schoolget(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    try {
      return await _schoolClient.get(
        path,
        queryParameters: query,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }

  // MARK: - AWS GET

  Future<Response> awsGet(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    try {
      return await _awsClient.get(
        path,
        queryParameters: query,
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }

  // MARK: - S3 PUT

  Future<Response> s3Put({
    required String presignedUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    try {
      return await _s3Client.put(
        presignedUrl,
        data: Stream.fromIterable(
          fileBytes.map((e) => [e]),
        ),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length,
          },
          followRedirects: false,
          validateStatus: (status) =>
          status != null && status < 400,
        ),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : _handleDioError(e);
    }
  }
}
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
      this.message, {
        this.statusCode,
      });

  @override
  String toString() => message;
}