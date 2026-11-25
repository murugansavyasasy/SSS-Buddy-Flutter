import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/model/FinancialYearModel.dart';
import '../auth/model/PaymentSubmissionModel.dart';
import '../core/aws/s3_upload_service.dart';
import '../core/network/DioClient.dart';
import '../core/storage/secure_storage.dart';
import 'app_endpoint.dart';

/// REST calls for Payment Submissions. Every request carries the login
/// token as `Authorization: Bearer <token>`. All of them need the role
/// permission PAYMENT_SUBMISSIONS; without it the server answers 403.
class PaymentSubmissionRepository {
  final DioClient _client;
  final S3UploadService _s3;

  PaymentSubmissionRepository(this._client) : _s3 = S3UploadService(_client);

  Dio get _dio => _client.dio;

  /// Login token from the in-memory session, falling back to the login
  /// response saved in secure storage (e.g. while the session is reloading).
  Future<String> _token() async {
    final live = await _client.getToken();
    if (live != null && live.isNotEmpty) return live;
    try {
      final raw = await SecureStorage.getLoginResponse();
      if (raw == null || raw.isEmpty) return '';
      final json = jsonDecode(raw);
      if (json is! Map) return '';
      final data = json['data'];
      final t = (data is Map ? data['token'] : null) ?? json['token'];
      return t?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<Options> _options({String? contentType}) async {
    final token = await _token();
    return Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      contentType: contentType,
    );
  }

  /// Dio errors are already turned into [ApiException] by DioClient's
  /// interceptor; unwrap them so screens can show the message.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiException) throw err;
      throw ApiException(e.message ?? 'Something went wrong. Please try again.',
          statusCode: e.response?.statusCode);
    }
  }

  void _ensureOk(Response res) {
    final body = res.data;
    if (body is Map) {
      final status = (body['status'] ?? body['Status'])?.toString().toLowerCase();
      if (status == 'error' || status == 'failed') {
        throw ApiException(
          (body['message'] ?? body['Message'] ?? 'Request failed').toString(),
          statusCode: res.statusCode,
        );
      }
    }
  }

  static Map<String, dynamic> _object(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return body.cast<String, dynamic>();
    }
    return const {};
  }

  static List<Map<String, dynamic>> _list(dynamic body) {
    final v = body is Map ? body['data'] : body;
    final list = v is Map ? (v['items'] ?? v['rows'] ?? v['list']) : v;
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// My (or my team's) submissions, newest first.
  Future<PsPage> fetchSubmissions({
    String status = '',
    bool mine = true,
    int page = 1,
    int limit = 25,
    String search = '',
  }) =>
      _guard(() async {
        final res = await _dio.get(
          AppEndpoint.paymentSubmissions,
          queryParameters: {
            if (status.isNotEmpty) 'status': status,
            'mine': mine,
            'page': page,
            'limit': limit,
            if (search.isNotEmpty) 'search': search,
          },
          options: await _options(),
        );
        _ensureOk(res);
        final items = _list(res.data).map(PaymentSubmission.fromJson).toList();
        final body = res.data;
        final pg = body is Map ? body['pagination'] : null;
        final totalPages = pg is Map ? int.tryParse('${pg['totalPages']}') ?? page : page;
        return PsPage(items: items, page: page, totalPages: totalPages);
      });

  /// False when the user's role has no PAYMENT_SUBMISSIONS permission (403).
  /// Any other failure (offline, server down) counts as allowed.
  Future<bool> hasAccess() async {
    try {
      await fetchSubmissions(limit: 1);
      return true;
    } on ApiException catch (e) {
      return e.statusCode != 403;
    } catch (_) {
      return true;
    }
  }

  /// Schools in the user's team with a pending proforma (at most 50).
  Future<List<PsCustomer>> fetchCustomers({String search = ''}) => _guard(() async {
        final res = await _dio.get(
          AppEndpoint.paymentSubmissionCustomers,
          queryParameters: {if (search.isNotEmpty) 'search': search},
          options: await _options(),
        );
        _ensureOk(res);
        return _list(res.data).map(PsCustomer.fromJson).toList();
      });

  /// Open proformas of a school and how much can still be claimed.
  Future<List<PsProforma>> fetchProformas(int customerId) => _guard(() async {
        final res = await _dio.get(
          AppEndpoint.paymentSubmissionProformas(customerId),
          options: await _options(),
        );
        _ensureOk(res);
        return _list(res.data).map(PsProforma.fromJson).toList();
      });

  /// Uploads a proof (image or PDF) and returns what the AI read from it,
  /// including the stored `proofUrl`. Takes 3–8 s.
  Future<PsExtraction> extractProof(String path, {void Function(double)? onProgress}) =>
      _guard(() async {
        final name = path.split(RegExp(r'[/\\]')).last;
        final form = FormData.fromMap({
          'proof': await MultipartFile.fromFile(
            path,
            filename: name,
            contentType: DioMediaType.parse(S3UploadService.contentTypeFor(path)),
          ),
        });
        final res = await _dio.post(
          AppEndpoint.paymentSubmissionExtract,
          data: form,
          options: (await _options()).copyWith(
            sendTimeout: const Duration(seconds: 90),
            receiveTimeout: const Duration(seconds: 60),
          ),
          onSendProgress: onProgress == null
              ? null
              : (sent, total) {
                  if (total > 0) onProgress(sent / total);
                },
        );
        // status "not_a_proof" / "failed" are answers, not errors.
        return PsExtraction.fromJson(_object(res.data));
      });

  /// Fallback when the AI read is down: stores the proof on S3 and returns
  /// its URL, sent in `proofUrls` without an extraction.
  Future<String> uploadProof(String path, {void Function(double)? onProgress}) => _s3.uploadFile(
        file: File(path),
        fileName: S3UploadService.scoreFileName(path),
        bucketPath: 'payment_proofs',
        contentType: S3UploadService.contentTypeFor(path),
        onProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );

  /// Values for the Mode dropdown.
  Future<List<Paymentmodemodel>> fetchPaymentModes() => _guard(() async {
        final res = await _dio.get(AppEndpoint.getPaymentMode, options: await _options());
        _ensureOk(res);
        return _list(res.data)
            .map(Paymentmodemodel.fromJson)
            .where((m) => m.value.isNotEmpty)
            .toList();
      });

  /// Returns the new submission (status pending) and the server's message.
  Future<(PaymentSubmission, String)> submit(SubmitPaymentRequest req) => _guard(() async {
        final res = await _dio.post(
          AppEndpoint.paymentSubmissions,
          data: req.toJson(),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
        final body = res.data;
        final message = body is Map ? (body['message'] ?? '').toString() : '';
        return (PaymentSubmission.fromJson(_object(body)), message);
      });

  Future<PaymentSubmission> fetchSubmission(int id) => _guard(() async {
        final res = await _dio.get(AppEndpoint.paymentSubmissionById(id), options: await _options());
        _ensureOk(res);
        return PaymentSubmission.fromJson(_object(res.data));
      });

  /// Cancels a pending submission (only the submitter can).
  Future<void> withdraw(int id) => _guard(() async {
        final res = await _dio.post(
          AppEndpoint.paymentSubmissionWithdraw(id),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
      });
}
