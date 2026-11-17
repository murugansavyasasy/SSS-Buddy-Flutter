import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints each API call once, as a single block with its request and
/// response, after the call finishes. Debug builds only.
///
///   ┌─ ✅ 200 POST https://host/api/mobile/login  ·  312 ms
///   │ Query   : {...}
///   │ Request : {...}
///   │ Status  : 200 OK
///   │ Response: {...}
///   └─────
///
/// Tokens are masked; file uploads are shown as a size, not as bytes.
class ApiLogInterceptor extends Interceptor {
  ApiLogInterceptor({this.maxBodyChars = 3000});

  /// Bodies longer than this are cut so one call can't flood the console.
  final int maxBodyChars;

  static const _startKey = '_apiLogStart';
  static final _encoder = const JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _print(response.requestOptions,
        status: response.statusCode, response: response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _print(
      err.requestOptions,
      status: err.response?.statusCode,
      response: err.response?.data,
      error: err.error?.toString() ?? err.message ?? err.type.name,
    );
    handler.next(err);
  }

  void _print(
    RequestOptions o, {
    int? status,
    dynamic response,
    String? error,
  }) {
    if (!kDebugMode) return;

    final start = o.extra[_startKey];
    final ms = start is DateTime
        ? ' · ${DateTime.now().difference(start).inMilliseconds} ms'
        : '';
    final icon = error == null ? '✅' : '❌';
    final code = status?.toString() ?? '---';

    final b = StringBuffer()
      ..writeln('┌─ $icon $code ${o.method} ${_url(o)}$ms');
    if (o.queryParameters.isNotEmpty) {
      _section(b, 'Query   ', o.queryParameters);
    }
    if (o.data != null) _section(b, 'Request ', _requestBody(o.data));
    b.writeln('│ Status  : $code${_reason(status)}');
    if (error != null) b.writeln('│ Error   : $error');
    if (response != null && response.toString().isNotEmpty) {
      _section(b, 'Response', response);
    }
    b.write('└─────');
    debugPrint(b.toString());
  }

  static String _reason(int? status) => switch (status) {
        null => ' (no response)',
        200 => ' OK',
        201 => ' Created',
        204 => ' No Content',
        400 => ' Bad Request',
        401 => ' Unauthorized',
        403 => ' Forbidden',
        404 => ' Not Found',
        408 => ' Timeout',
        409 => ' Conflict',
        422 => ' Unprocessable',
        429 => ' Too Many Requests',
        500 => ' Server Error',
        502 => ' Bad Gateway',
        503 => ' Unavailable',
        _ => '',
      };

  /// Full URL without the query string (query is printed separately).
  /// Presigned S3 URLs carry long signatures; show only the path for them.
  String _url(RequestOptions o) {
    final uri = o.uri;
    final base = uri.replace(query: '').toString().replaceAll(RegExp(r'\?$'), '');
    return uri.queryParameters.containsKey('X-Amz-Signature')
        ? '$base  (presigned)'
        : base;
  }

  dynamic _requestBody(dynamic data) {
    if (data is FormData) {
      return {
        for (final f in data.fields) f.key: f.value,
        for (final f in data.files)
          f.key: '<file ${f.value.filename ?? ''} · ${f.value.length} bytes>',
      };
    }
    if (data is Stream) return '<binary stream>';
    if (data is List<int>) return '<binary ${data.length} bytes>';
    return data;
  }

  void _section(StringBuffer b, String label, dynamic value) {
    var text = _format(value);
    if (text.length > maxBodyChars) {
      text = '${text.substring(0, maxBodyChars)}\n… (${text.length - maxBodyChars} more chars)';
    }
    final lines = text.split('\n');
    b.writeln('│ $label: ${lines.first}');
    for (final line in lines.skip(1)) {
      b.writeln('│           $line');
    }
  }

  String _format(dynamic value) {
    dynamic v = _mask(value);
    if (v is String) {
      final t = v.trim();
      if (t.startsWith('{') || t.startsWith('[')) {
        try {
          v = _mask(jsonDecode(t));
        } catch (_) {
          return v;
        }
      } else {
        return v;
      }
    }
    try {
      return _encoder.convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  static const _secretKeys = {'password', 'token', 'authorization'};

  dynamic _mask(dynamic v) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          e.key: _secretKeys.contains(e.key.toString().toLowerCase()) &&
                  e.value is String &&
                  (e.value as String).isNotEmpty
              ? '••••'
              : _mask(e.value),
      };
    }
    if (v is List) {
      // Big lists (e.g. the ~2 MB school list) would take seconds to
      // pretty-print on the UI thread in debug; log only the first few rows.
      if (v.length > _maxListItems) {
        return [
          ...v.take(_maxListItems).map(_mask),
          '… ${v.length - _maxListItems} more items (${v.length} total)',
        ];
      }
      return v.map(_mask).toList();
    }
    return v;
  }

  static const _maxListItems = 5;
}
