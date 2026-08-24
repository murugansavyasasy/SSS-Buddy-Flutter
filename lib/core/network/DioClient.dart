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
    return Dio(
      BaseOptions(
        baseUrl: baseurl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )..interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  Future<Response> get(
      String path, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? headers,
      }) async {
    return await _vimsClient.get(
      path,
      queryParameters: query,
      options: Options(
        headers: headers,
      ),
    );
  }

  Future<Response> post(
      String path, {
        Object? body,
      }) async {
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
  }

  Future<String?> getToken() async {
    final loginState = ref.read(loginProvider);

    final loginData = loginState.value;

    if (loginData == null) {
      return null;
    }

    return loginData.token;
  }

  Future<Response> schoolPost(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    return await _schoolClient.post(
      path,
      data: body,
    );
  }

  Future<Response> schoolget(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    return await _schoolClient.get(
      path,
      queryParameters: query,
    );
  }

  Future<Response> awsGet(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    return await _awsClient.get(
      path,
      queryParameters: query,
    );
  }

  Future<Response> s3Put({
    required String presignedUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
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
  }
}