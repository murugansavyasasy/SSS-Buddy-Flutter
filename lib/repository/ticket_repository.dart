import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/model/ExhibitionModel.dart' show extractList, extractObject;
import '../auth/model/TicketModel.dart';
import '../core/aws/s3_upload_service.dart';
import '../core/network/DioClient.dart';
import 'app_endpoint.dart';

/// Storage for tickets. [LocalTicketRepository] is the demo mode used until
/// the backend is ready; [ApiTicketRepository] follows docs/TICKET_API.md.
/// Switch in `ticketRepositoryProvider` (viewModel/ticket_viewmodel.dart).
abstract class TicketRepository {
  /// [all] = every user's tickets (Admin / Support); else the ones [userId]
  /// raised or is assigned to.
  Future<List<Ticket>> fetchTickets({required String userId, required bool all});

  /// Assigns [ticketId] to [to] (null = unassign). Anyone may assign.
  Future<Ticket> assign(String ticketId, TicketAssignee? to, {required String byName});

  /// People a ticket can be assigned to. Empty when the API has no list
  /// (the view model then offers the reporting members).
  Future<List<TicketAssignee>> fetchAssignees();

  Future<Ticket> createTicket(
    CreateTicketRequest req, {
    required String userId,
    required String userName,
  });

  Future<Ticket> updateStatus(
    String ticketId,
    TicketStatus status, {
    String note = '',
    required String byName,
  });

  /// Uploads an image / video and returns the URL (or path) to store.
  Future<String> uploadAttachment(String path);
}

/// Demo mode: tickets kept in shared_preferences on this phone only. Every
/// user who logs in on the same phone sees the same list, so raising a
/// ticket and completing it as Admin can be tried on one device.
class LocalTicketRepository implements TicketRepository {
  static const _key = 'tickets_demo_v1';
  final _random = Random();

  Future<List<Ticket>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Ticket.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Ticket> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((t) => t.toJson()).toList()));
  }

  @override
  Future<List<Ticket>> fetchTickets({required String userId, required bool all}) async {
    final items = await _read();
    return all
        ? items
        : items.where((t) => t.raisedById == userId || t.assignedToId == userId).toList();
  }

  @override
  Future<Ticket> assign(String ticketId, TicketAssignee? to, {required String byName}) async {
    final items = await _read();
    final i = items.indexWhere((t) => t.id == ticketId);
    if (i < 0) throw ApiException('Ticket not found');
    final now = DateTime.now();
    final t = items[i].copyWith(
      assignee: to,
      unassign: to == null,
      updatedAt: now,
      history: [
        ...items[i].history,
        TicketHistory(
          status: items[i].status,
          event: 'assign',
          assignedToName: to?.name ?? '',
          byName: byName,
          at: now,
        ),
      ],
    );
    items[i] = t;
    await _write(items);
    return t;
  }

  @override
  Future<List<TicketAssignee>> fetchAssignees() async => const [];

  @override
  Future<Ticket> createTicket(
    CreateTicketRequest req, {
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    final t = Ticket(
      id: '${now.millisecondsSinceEpoch}${_random.nextInt(900) + 100}',
      app: req.app,
      description: req.description,
      priority: req.priority,
      raisedById: userId,
      raisedByName: userName,
      createdAt: now,
      updatedAt: now,
      attachments: req.attachments,
      platform: req.platform,
      deviceName: req.deviceName.trim(),
      deviceModel: req.deviceModel.trim(),
      assignedToId: req.assignee?.id ?? '',
      assignedToName: req.assignee?.name ?? '',
      history: [
        TicketHistory(status: TicketStatus.open, byName: userName, at: now),
        if (req.assignee != null)
          TicketHistory(
            status: TicketStatus.open,
            event: 'assign',
            assignedToName: req.assignee!.name,
            byName: userName,
            at: now,
          ),
      ],
    );
    await _write([...await _read(), t]);
    return t;
  }

  @override
  Future<Ticket> updateStatus(
    String ticketId,
    TicketStatus status, {
    String note = '',
    required String byName,
  }) async {
    final items = await _read();
    final i = items.indexWhere((t) => t.id == ticketId);
    if (i < 0) throw ApiException('Ticket not found');
    final now = DateTime.now();
    final t = items[i].copyWith(
      status: status,
      updatedAt: now,
      history: [
        ...items[i].history,
        TicketHistory(status: status, note: note, byName: byName, at: now),
      ],
    );
    items[i] = t;
    await _write(items);
    return t;
  }

  @override
  Future<String> uploadAttachment(String path) async => path;
}

/// REST implementation of docs/TICKET_API.md (VIMS base URL, bearer token).
class ApiTicketRepository implements TicketRepository {
  final DioClient _client;
  final S3UploadService _s3;

  ApiTicketRepository(this._client) : _s3 = S3UploadService(_client);

  Dio get _dio => _client.dio;

  Future<Options> _options() async {
    final token = await _client.getToken() ?? '';
    return Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      contentType: Headers.jsonContentType,
    );
  }

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
      if (status == 'error' || status == 'failed' || body['success'] == false) {
        throw ApiException(
          (body['message'] ?? body['Message'] ?? 'Request failed').toString(),
          statusCode: res.statusCode,
        );
      }
    }
  }

  @override
  Future<List<Ticket>> fetchTickets({required String userId, required bool all}) =>
      _guard(() async {
        final res = await _dio.get(
          AppEndpoint.tickets,
          queryParameters: {'scope': all ? 'all' : 'mine'},
          options: await _options(),
        );
        _ensureOk(res);
        return extractList(res.data, ['tickets']).map(Ticket.fromJson).toList();
      });

  @override
  Future<Ticket> createTicket(
    CreateTicketRequest req, {
    required String userId,
    required String userName,
  }) =>
      _guard(() async {
        final res = await _dio.post(
          AppEndpoint.tickets,
          data: req.toJson(),
          options: await _options(),
        );
        _ensureOk(res);
        return Ticket.fromJson(extractObject(res.data, ['ticket']));
      });

  @override
  Future<Ticket> updateStatus(
    String ticketId,
    TicketStatus status, {
    String note = '',
    required String byName,
  }) =>
      _guard(() async {
        final res = await _dio.put(
          AppEndpoint.ticketStatus(ticketId),
          data: {'status': status.apiValue, 'note': note},
          options: await _options(),
        );
        _ensureOk(res);
        return Ticket.fromJson(extractObject(res.data, ['ticket']));
      });

  @override
  Future<Ticket> assign(String ticketId, TicketAssignee? to, {required String byName}) =>
      _guard(() async {
        final res = await _dio.put(
          AppEndpoint.ticketAssign(ticketId),
          data: {'assignedToId': to?.id ?? ''},
          options: await _options(),
        );
        _ensureOk(res);
        return Ticket.fromJson(extractObject(res.data, ['ticket']));
      });

  @override
  Future<List<TicketAssignee>> fetchAssignees() => _guard(() async {
        final res = await _dio.get(AppEndpoint.ticketAssignees, options: await _options());
        _ensureOk(res);
        return [
          for (final m in extractList(res.data, ['assignees', 'users']))
            if ('${m['id'] ?? m['userId'] ?? ''}'.isNotEmpty)
              (id: '${m['id'] ?? m['userId']}', name: '${m['name'] ?? m['userName'] ?? ''}'),
        ];
      });

  @override
  Future<String> uploadAttachment(String path) => _guard(() => _s3.uploadFile(
        file: File(path),
        fileName: S3UploadService.scoreFileName(path),
        bucketPath: 'tickets',
        contentType: ticketAttachmentContentType(path),
      ));
}
