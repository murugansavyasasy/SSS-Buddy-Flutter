/// Ticket Raising: app issues reported by users. Admin / Support change the
/// status; the person who raised it is notified when it is Completed.
/// Backend contract: docs/TICKET_API.md.

enum TicketStatus { open, inProgress, completed }

/// 'Open' | 'InProgress' | 'Completed' (any case, spaces / _ / - ignored).
TicketStatus parseTicketStatus(String s) =>
    switch (s.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      'inprogress' => TicketStatus.inProgress,
      'completed' => TicketStatus.completed,
      _ => TicketStatus.open,
    };

extension TicketStatusX on TicketStatus {
  String get label => switch (this) {
        TicketStatus.open => 'Open',
        TicketStatus.inProgress => 'In Progress',
        TicketStatus.completed => 'Completed',
      };

  String get apiValue => switch (this) {
        TicketStatus.open => 'Open',
        TicketStatus.inProgress => 'InProgress',
        TicketStatus.completed => 'Completed',
      };
}

enum TicketPriority { low, medium, high }

TicketPriority parseTicketPriority(String s) => switch (s.trim().toLowerCase()) {
      'high' => TicketPriority.high,
      'low' => TicketPriority.low,
      _ => TicketPriority.medium,
    };

extension TicketPriorityX on TicketPriority {
  String get label => switch (this) {
        TicketPriority.low => 'Low',
        TicketPriority.medium => 'Medium',
        TicketPriority.high => 'High',
      };

  String get apiValue => label;
}

/// Company apps a ticket can be raised for (same list as Important Info).
const ticketApps = <String>[
  'School Chimes',
  'Gradit',
  "Let's Reach",
  'SSS Score',
  'Other',
];

enum TicketAttachmentType { image, video }

/// Image or video attached to a ticket: S3 URL, or a local path in demo mode.
class TicketAttachment {
  final String url;
  final TicketAttachmentType type;

  const TicketAttachment({required this.url, required this.type});

  bool get isVideo => type == TicketAttachmentType.video;

  factory TicketAttachment.fromJson(Map<String, dynamic> j) {
    final url = _s(j, ['url', 'Url']);
    final t = _s(j, ['type', 'Type']).toLowerCase();
    return TicketAttachment(
      url: url,
      type: t == 'video' || (t.isEmpty && isTicketVideoPath(url))
          ? TicketAttachmentType.video
          : TicketAttachmentType.image,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'type': type.name};
}

/// Video by file extension (ignores any ?query).
bool isTicketVideoPath(String path) {
  final p = path.split('?').first.toLowerCase();
  return const ['.mp4', '.mov', '.m4v', '.3gp', '.webm', '.mkv'].any(p.endsWith);
}

/// Content type for uploading a ticket attachment.
String ticketAttachmentContentType(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.mov')) return 'video/quicktime';
  if (p.endsWith('.3gp')) return 'video/3gpp';
  if (p.endsWith('.webm')) return 'video/webm';
  if (p.endsWith('.mkv')) return 'video/x-matroska';
  if (p.endsWith('.mp4') || p.endsWith('.m4v')) return 'video/mp4';
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.heic')) return 'image/heic';
  if (p.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// Admin and Support can change a ticket's status.
bool canManageTickets(String roleCode) {
  final r = roleCode.trim().toLowerCase();
  return r == 'admin' || r == 'support';
}

String _s(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return '';
}

DateTime? _date(String s) => s.isEmpty ? null : DateTime.tryParse(s)?.toLocal();

/// One status change, shown as the ticket timeline.
class TicketHistory {
  final TicketStatus status;
  final String note;
  final String byName;
  final DateTime? at;

  /// `status` (status change / raised) or `assign` (assignee changed).
  final String event;

  /// For `assign` events: who it was assigned to ('' = unassigned).
  final String assignedToName;

  const TicketHistory({
    required this.status,
    this.note = '',
    this.byName = '',
    this.at,
    this.event = 'status',
    this.assignedToName = '',
  });

  bool get isAssign => event == 'assign';

  factory TicketHistory.fromJson(Map<String, dynamic> j) => TicketHistory(
        status: parseTicketStatus(_s(j, ['status', 'Status'])),
        note: _s(j, ['note', 'Note']),
        byName: _s(j, ['byName', 'ByName', 'updatedByName']),
        at: _date(_s(j, ['at', 'At', 'createdAt'])),
        event: _s(j, ['event', 'Event']).isEmpty ? 'status' : _s(j, ['event', 'Event']),
        assignedToName: _s(j, ['assignedToName', 'AssignedToName']),
      );

  Map<String, dynamic> toJson() => {
        'status': status.apiValue,
        'note': note,
        'byName': byName,
        'at': at?.toUtc().toIso8601String(),
        'event': event,
        if (isAssign) 'assignedToName': assignedToName,
      };
}

/// Someone a ticket can be assigned to.
typedef TicketAssignee = ({String id, String name});

class Ticket {
  final String id;

  /// Which company app the issue is in (one of [ticketApps]).
  final String app;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final String raisedById;
  final String raisedByName;

  /// Who is working on it ('' = unassigned). Anyone can assign anyone.
  final String assignedToId;
  final String assignedToName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Images / videos showing the issue.
  final List<TicketAttachment> attachments;
  final String platform;

  /// Optional, typed by the user: the phone where the issue happened
  /// (e.g. "Redmi Note 12") and its model / OS ("Android 14").
  final String deviceName;
  final String deviceModel;

  /// "Redmi Note 12 · Android 14", or the auto-detected [platform].
  String get deviceLabel {
    final typed = [deviceName.trim(), deviceModel.trim()].where((s) => s.isNotEmpty).join(' · ');
    return typed.isNotEmpty ? typed : platform;
  }

  /// Oldest first.
  final List<TicketHistory> history;

  const Ticket({
    required this.id,
    this.app = 'Other',
    this.description = '',
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.raisedById = '',
    this.raisedByName = '',
    this.assignedToId = '',
    this.assignedToName = '',
    this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.platform = '',
    this.deviceName = '',
    this.deviceModel = '',
    this.history = const [],
  });

  /// First line of the description, for cards and notifications.
  String get headline {
    final line = description.trim().split('\n').first.trim();
    return line.length > 90 ? '${line.substring(0, 90)}…' : line;
  }

  String get displayId => id.length > 6 ? '#${id.substring(id.length - 6)}' : '#$id';

  /// Latest note added with a status change (e.g. the fix description).
  String get latestNote {
    for (final h in history.reversed) {
      if (h.note.isNotEmpty) return h.note;
    }
    return '';
  }

  factory Ticket.fromJson(Map<String, dynamic> j) {
    final h = j['history'] ?? j['History'];
    final a = j['attachments'] ?? j['Attachments'];
    final app = _s(j, ['app', 'App', 'appName', 'AppName']);
    return Ticket(
      id: _s(j, ['id', 'Id', 'ticketId', 'TicketId']),
      app: app.isEmpty ? 'Other' : app,
      description: _s(j, ['description', 'Description']),
      priority: parseTicketPriority(_s(j, ['priority', 'Priority'])),
      status: parseTicketStatus(_s(j, ['status', 'Status'])),
      raisedById: _s(j, ['raisedById', 'RaisedById', 'userId']),
      raisedByName: _s(j, ['raisedByName', 'RaisedByName']),
      assignedToId: _s(j, ['assignedToId', 'AssignedToId']),
      assignedToName: _s(j, ['assignedToName', 'AssignedToName']),
      createdAt: _date(_s(j, ['createdAt', 'CreatedAt'])),
      updatedAt: _date(_s(j, ['updatedAt', 'UpdatedAt'])),
      attachments: a is List
          ? a
              .map((e) => e is Map
                  ? TicketAttachment.fromJson(e.cast<String, dynamic>())
                  : TicketAttachment.fromJson({'url': '$e'}))
              .where((e) => e.url.isNotEmpty)
              .toList()
          : const [],
      platform: _s(j, ['platform', 'Platform']),
      deviceName: _s(j, ['deviceName', 'DeviceName']),
      deviceModel: _s(j, ['deviceModel', 'DeviceModel']),
      history: h is List
          ? h.whereType<Map>().map((e) => TicketHistory.fromJson(e.cast<String, dynamic>())).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'app': app,
        'description': description,
        'priority': priority.apiValue,
        'status': status.apiValue,
        'raisedById': raisedById,
        'raisedByName': raisedByName,
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'platform': platform,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'history': history.map((e) => e.toJson()).toList(),
      };

  bool get isAssigned => assignedToId.isNotEmpty;

  Ticket copyWith({
    TicketStatus? status,
    DateTime? updatedAt,
    List<TicketHistory>? history,
    TicketAssignee? assignee,
    bool unassign = false,
  }) =>
      Ticket(
        id: id,
        app: app,
        description: description,
        priority: priority,
        status: status ?? this.status,
        raisedById: raisedById,
        raisedByName: raisedByName,
        assignedToId: unassign ? '' : (assignee?.id ?? assignedToId),
        assignedToName: unassign ? '' : (assignee?.name ?? assignedToName),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        attachments: attachments,
        platform: platform,
        deviceName: deviceName,
        deviceModel: deviceModel,
        history: history ?? this.history,
      );
}

/// Body of POST api/mobile/tickets.
class CreateTicketRequest {
  final String app;
  final String description;
  final TicketPriority priority;
  final List<TicketAttachment> attachments;
  final String platform;

  /// Optional assignee chosen while raising.
  final TicketAssignee? assignee;

  /// Optional device details typed by the user.
  final String deviceName;
  final String deviceModel;

  const CreateTicketRequest({
    required this.app,
    required this.description,
    this.priority = TicketPriority.medium,
    this.attachments = const [],
    this.platform = '',
    this.assignee,
    this.deviceName = '',
    this.deviceModel = '',
  });

  Map<String, dynamic> toJson() => {
        'app': app,
        'description': description,
        'priority': priority.apiValue,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'platform': platform,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        if (assignee != null) 'assignedToId': assignee!.id,
      };
}

/// Tickets of [userId] that are Completed now but were not Completed at the
/// last check ([lastSeen]: ticket id → status apiValue). Tickets missing from
/// [lastSeen] are new to this device and never notify, so the first check
/// after install or login stays quiet.
List<Ticket> newlyCompletedTickets(
  List<Ticket> tickets,
  Map<String, String> lastSeen,
  String userId,
) =>
    tickets
        .where((t) =>
            t.raisedById == userId &&
            t.status == TicketStatus.completed &&
            lastSeen.containsKey(t.id) &&
            lastSeen[t.id] != TicketStatus.completed.apiValue)
        .toList();

/// Tickets now assigned to [userId] that were not assigned to them at the
/// last check ([seenAssigned]). Quiet on the [firstCheck] after install or
/// login, and skips tickets the user assigned to themselves ([myName] made
/// the latest assignment).
List<Ticket> newlyAssignedTickets(
  List<Ticket> tickets,
  Set<String> seenAssigned,
  String userId, {
  required bool firstCheck,
  String myName = '',
}) {
  if (firstCheck) return const [];
  return tickets.where((t) {
    if (t.assignedToId != userId || seenAssigned.contains(t.id)) return false;
    final lastAssign = t.history.lastWhere(
      (h) => h.isAssign,
      orElse: () => const TicketHistory(status: TicketStatus.open),
    );
    return myName.isEmpty || lastAssign.byName != myName;
  }).toList();
}
