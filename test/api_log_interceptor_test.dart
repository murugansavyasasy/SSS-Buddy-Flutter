import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/core/network/api_log_interceptor.dart';

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? _, Future<void>? __) async =>
      ResponseBody.fromString('{"status":"success","token":"abc123","data":[1,2]}', 200,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

void main() {
  test('prints one block per call with request + response, secrets masked', () async {
    final logs = <String>[];
    final old = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
    addTearDown(() => debugPrint = old);

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
      ..httpClientAdapter = _FakeAdapter()
      ..interceptors.add(ApiLogInterceptor());
    await dio.post('api/mobile/login', data: {'employeeId': 'E1', 'password': 'secret'});

    expect(logs, hasLength(1));
    final out = logs.single;
    expect(out, contains('✅ 200 POST https://example.test/api/mobile/login'));
    expect(out, contains('"employeeId": "E1"'));
    expect(out, contains('"status": "success"'));
    expect(out, isNot(contains('secret')));
    expect(out, isNot(contains('abc123')));
  });
}
