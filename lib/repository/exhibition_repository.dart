import 'dart:convert';

import 'package:dio/dio.dart';

import '../auth/model/ExhibitionModel.dart';
import '../core/network/DioClient.dart';
import 'app_endpoint.dart';

/// REST calls for the Exhibitions module. Every request carries the login
/// token as `Authorization: Bearer <token>`.
class ExhibitionRepository {
  final DioClient _client;

  ExhibitionRepository(this._client);

  Dio get _dio => _client.dio;

  Future<Options> _options({String? contentType}) async {
    final token = await _client.getToken();
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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
      final success = body['success'] ?? body['Success'];
      if (status == 'error' || status == 'failed' || success == false) {
        throw ApiException(
          (body['message'] ?? body['Message'] ?? 'Request failed').toString(),
          statusCode: res.statusCode,
        );
      }
    }
  }

  // MARK: Exhibitions

  Future<List<Exhibition>> fetchExhibitions({String status = '', String search = ''}) =>
      _guard(() async {
        final res = await _dio.get(
          AppEndpoint.exhibitions,
          queryParameters: {'status': status, 'search': search},
          options: await _options(),
        );
        _ensureOk(res);
        return extractList(res.data, ['exhibitions']).map(Exhibition.fromJson).toList();
      });

  Future<Exhibition> fetchExhibition(String id) => _guard(() async {
        final res = await _dio.get(AppEndpoint.exhibitionById(id), options: await _options());
        _ensureOk(res);
        return Exhibition.fromJson(extractObject(res.data, ['exhibition']));
      });

  /// Returns the created exhibition (or a minimal one if the API only returns an id).
  Future<Exhibition> createExhibition(CreateExhibitionRequest req) => _guard(() async {
        final res = await _dio.post(
          AppEndpoint.exhibitions,
          data: req.toJson(),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
        final created = Exhibition.fromJson(extractObject(res.data, ['exhibition']));
        if (created.name.isNotEmpty) return created;
        return Exhibition(
          id: created.id,
          name: req.name,
          venue: req.venue,
          city: req.city,
          startDate: req.startDate,
          endDate: req.endDate,
          status: req.status,
          notes: req.notes,
          attendees: req.attendees,
          attendeeCount: req.attendees.length,
        );
      });

  /// PUT /exhibitions/:id with the same body as create.
  /// NOTE: confirm this endpoint with the backend.
  Future<void> updateExhibition(String id, CreateExhibitionRequest req) => _guard(() async {
        final res = await _dio.put(
          AppEndpoint.exhibitionById(id),
          data: req.toJson(),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
      });

  /// DELETE /exhibitions/:id. Only the creator sees this option.
  /// NOTE: confirm this endpoint with the backend.
  Future<void> deleteExhibition(String id) => _guard(() async {
        final res = await _dio.delete(
          AppEndpoint.exhibitionById(id),
          options: await _options(),
        );
        _ensureOk(res);
      });

  // MARK: Voice templates
  // NOTE: confirm these three endpoints with the backend.

  Future<List<DemoTemplate>> fetchTemplates() => _guard(() async {
        final res = await _dio.get(AppEndpoint.exhibitionTemplates, options: await _options());
        _ensureOk(res);
        return extractList(res.data, ['templates']).map(DemoTemplate.fromJson).toList();
      });

  /// Multipart: the WAV (8 kHz, mono) as `file`, plus title, description and
  /// durationSeconds.
  Future<void> createTemplate({
    required String title,
    required String description,
    required String wavPath,
    required Duration duration,
  }) =>
      _guard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            wavPath,
            filename: 'template_${DateTime.now().millisecondsSinceEpoch}.wav',
            contentType: DioMediaType('audio', 'wav'),
          ),
          'title': title,
          'description': description,
          'durationSeconds': duration.inSeconds,
        });
        final res = await _dio.post(
          AppEndpoint.exhibitionTemplates,
          data: form,
          options: (await _options()).copyWith(
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 1),
          ),
        );
        _ensureOk(res);
      });

  Future<void> deleteTemplate(String id) => _guard(() async {
        final res = await _dio.delete(AppEndpoint.exhibitionTemplateById(id), options: await _options());
        _ensureOk(res);
      });

  // MARK: Demos

  Future<List<ExhibitionDemo>> fetchDemos(String exhibitionId) => _guard(() async {
        final res = await _dio.get(AppEndpoint.exhibitionDemos(exhibitionId),
            options: await _options());
        _ensureOk(res);
        return extractList(res.data, ['demos']).map(ExhibitionDemo.fromJson).toList();
      });

  /// Template voice: JSON with `audioUrl`. Returns the new demo id ('' if the
  /// response does not include one).
  Future<String> sendTemplateDemo({
    required String exhibitionId,
    required String audioUrl,
    required List<String> visitorNumbers,
    String visitorName = '',
  }) =>
      _guard(() async {
        final res = await _dio.post(
          AppEndpoint.exhibitionDemos(exhibitionId),
          data: {
            'visitorName': visitorName,
            'visitorNumbers': visitorNumbers,
            'audioUrl': audioUrl,
          },
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
        return _demoId(res.data);
      });

  /// Custom recording: multipart with the WAV (8 kHz, mono) as `file`.
  Future<String> sendRecordedDemo({
    required String exhibitionId,
    required String wavPath,
    required List<String> visitorNumbers,
    String visitorName = '',
    void Function(double progress)? onProgress,
  }) =>
      _guard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            wavPath,
            filename: 'demo_${DateTime.now().millisecondsSinceEpoch}.wav',
            contentType: DioMediaType('audio', 'wav'),
          ),
          'visitorNumbers': jsonEncode(visitorNumbers),
          'visitorName': visitorName,
        });
        final res = await _dio.post(
          AppEndpoint.exhibitionDemos(exhibitionId),
          data: form,
          options: (await _options()).copyWith(
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 1),
          ),
          onSendProgress: onProgress == null
              ? null
              : (sent, total) {
                  if (total > 0) onProgress(sent / total);
                },
        );
        _ensureOk(res);
        return _demoId(res.data);
      });

  String _demoId(dynamic body) {
    final o = extractObject(body, ['demo']);
    for (final k in ['id', 'Id', 'demoId', 'DemoId', '_id']) {
      final v = o[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  // MARK: Leads

  Future<List<ExhibitionLead>> fetchLeads(String exhibitionId) => _guard(() async {
        final res = await _dio.get(AppEndpoint.exhibitionLeads(exhibitionId),
            options: await _options());
        _ensureOk(res);
        return extractList(res.data, ['leads', 'interests']).map(ExhibitionLead.fromJson).toList();
      });

  /// Lead linked to a demo. Without [demoId] it is a standalone lead for the
  /// exhibition, posted to `/exhibitions/:id/leads`.
  /// NOTE: that standalone endpoint is not in the current API list; the
  /// backend needs to add it (or accept a null demoId) for this to work.
  Future<void> captureLead({
    required String exhibitionId,
    String? demoId,
    required CaptureLeadRequest req,
  }) =>
      _guard(() async {
        final path = (demoId != null && demoId.isNotEmpty)
            ? AppEndpoint.exhibitionDemoInterest(demoId)
            : AppEndpoint.exhibitionLeads(exhibitionId);
        final res = await _dio.post(
          path,
          data: req.toJson(),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
      });

  /// PUT /exhibitions/leads/:leadId with the same body as capture.
  /// NOTE: confirm this endpoint with the backend.
  Future<void> updateLead(String leadId, CaptureLeadRequest req) => _guard(() async {
        final res = await _dio.put(
          AppEndpoint.exhibitionLeadById(leadId),
          data: req.toJson(),
          options: await _options(contentType: Headers.jsonContentType),
        );
        _ensureOk(res);
      });
}
