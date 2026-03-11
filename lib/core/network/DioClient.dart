import 'package:dio/dio.dart';
import 'package:sssbuddy/repository/app_url.dart';

class Dioclient {
  late final Dio dio;

  Dioclient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppUrl.vimsUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return await dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {Map<String, dynamic>? body}) async {
    return await dio.post(path, data: body);
  }
}
