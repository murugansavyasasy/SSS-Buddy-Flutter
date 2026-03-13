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

  Future<Response> get(
    String path, {
    Map<String, dynamic>? query,
    bool useSchoolApi = false,
  }) async {
    final url = useSchoolApi ? AppUrl.schoolUrl + path : path;

    return await dio.get(url, queryParameters: query);
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool useSchoolApi = false,
  }) async {
    final url = useSchoolApi ? AppUrl.schoolUrl + path : path;

    return await dio.post(url, data: body);
  }
}
