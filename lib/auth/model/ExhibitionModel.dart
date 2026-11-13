/// Models for the Exhibitions module (trade-show voice demos and leads).
///
/// The parsers accept both camelCase and PascalCase keys and a few common
/// alternative names, because the /api/mobile/exhibitions responses are new.
/// Adjust the key lists in [_pick] calls once the backend contract is final.

dynamic _pick(Map m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k];
  }
  return null;
}

String _str(Map m, List<String> keys, [String fallback = '']) {
  final v = _pick(m, keys);
  return v == null ? fallback : v.toString();
}

int _int(Map m, List<String> keys, [int fallback = 0]) {
  final v = _pick(m, keys);
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _date(Map m, List<String> keys) {
  final v = _pick(m, keys);
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<Map<String, dynamic>> _maps(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}

/// Pulls the list out of `{data: [...]}`, `{data: {items: [...]}}` or a bare list.
List<Map<String, dynamic>> extractList(dynamic body, [List<String> keys = const []]) {
  if (body is List) return _maps(body);
  if (body is Map) {
    for (final k in [...keys, 'items', 'list', 'rows', 'result', 'records']) {
      if (body[k] is List) return _maps(body[k]);
    }
    final data = body['data'] ?? body['Data'];
    if (data != null) return extractList(data, keys);
  }
  return const [];
}

/// Pulls the object out of `{data: {...}}` or a bare object.
Map<String, dynamic> extractObject(dynamic body, [List<String> keys = const []]) {
  if (body is Map) {
    for (final k in keys) {
      if (body[k] is Map) return (body[k] as Map).cast<String, dynamic>();
    }
    final data = body['data'] ?? body['Data'];
    if (data is Map) return extractObject(data, keys);
    return body.cast<String, dynamic>();
  }
  return const {};
}

/// Strips everything but digits and a leading 91 / 0, leaving a 10-digit number.
/// Zero code point of each Unicode decimal-digit block a phone keyboard in
/// India may send (e.g. Hindi / Tamil keyboards type १२३ / ௧௨௩ instead of 123).
const _digitZeros = [
  0x0660, 0x06F0, // Arabic-Indic, Extended Arabic-Indic
  0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, // Devanagari, Bengali, Gurmukhi, Gujarati, Oriya
  0x0BE6, 0x0C66, 0x0CE6, 0x0D66, // Tamil, Telugu, Kannada, Malayalam
  0xFF10, // Fullwidth
];

/// Converts any of the digits above to ASCII 0-9; other characters unchanged.
String asciiDigits(String s) {
  final out = StringBuffer();
  for (final c in s.runes) {
    var mapped = c;
    for (final z in _digitZeros) {
      if (c >= z && c <= z + 9) {
        mapped = 0x30 + (c - z);
        break;
      }
    }
    out.writeCharCode(mapped);
  }
  return out.toString();
}

String normalizeIndianMobile(String raw) {
  var d = asciiDigits(raw).replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  return d;
}

bool isValidIndianMobile(String digits) => RegExp(r'^\d{10}$').hasMatch(digits);

String formatIndianMobile(String digits) {
  final d = normalizeIndianMobile(digits);
  if (d.length != 10) return digits;
  return '+91 ${d.substring(0, 5)} ${d.substring(5)}';
}

enum ExhibitionStatus { active, completed }

ExhibitionStatus _exStatus(String s) =>
    s.toLowerCase().startsWith('complete') ? ExhibitionStatus.completed : ExhibitionStatus.active;

extension ExhibitionStatusX on ExhibitionStatus {
  String get label => this == ExhibitionStatus.active ? 'Active' : 'Completed';
  String get apiValue => this == ExhibitionStatus.active ? 'active' : 'completed';
}

class Attendee {
  final String name;
  final String mobile;

  const Attendee({required this.name, required this.mobile});

  factory Attendee.fromJson(Map<String, dynamic> j) => Attendee(
        name: _str(j, ['name', 'Name', 'attendeeName', 'memberName']),
        mobile: normalizeIndianMobile(
            _str(j, ['mobile', 'Mobile', 'mobileNumber', 'phone', 'number'])),
      );

  Map<String, dynamic> toJson() => {'name': name, 'mobile': mobile};
}

class Exhibition {
  final String id;
  final String name;
  final String venue;
  final String city;
  final DateTime? startDate;
  final DateTime? endDate;
  final ExhibitionStatus status;
  final String notes;
  final List<Attendee> attendees;
  final int attendeeCount;
  final int demoCount;
  final int leadCount;
  final DateTime? createdAt;

  /// Creator's display name and user id, as far as the API sends them.
  final String createdBy;
  final String createdById;

  const Exhibition({
    required this.id,
    required this.name,
    this.venue = '',
    this.city = '',
    this.startDate,
    this.endDate,
    this.status = ExhibitionStatus.active,
    this.notes = '',
    this.attendees = const [],
    this.attendeeCount = 0,
    this.demoCount = 0,
    this.leadCount = 0,
    this.createdAt,
    this.createdBy = '',
    this.createdById = '',
  });

  factory Exhibition.fromJson(Map<String, dynamic> j) {
    final attendees = _maps(_pick(j, ['attendees', 'Attendees', 'team', 'travellingTeam']))
        .map(Attendee.fromJson)
        .toList();
    return Exhibition(
      id: _str(j, ['id', 'Id', 'exhibitionId', 'ExhibitionId', '_id']),
      name: _str(j, ['name', 'Name', 'exhibitionName']),
      venue: _str(j, ['venue', 'Venue']),
      city: _str(j, ['city', 'City']),
      startDate: _date(j, ['startDate', 'StartDate', 'start_date']),
      endDate: _date(j, ['endDate', 'EndDate', 'end_date']),
      status: _exStatus(_str(j, ['status', 'Status'], 'active')),
      notes: _str(j, ['notes', 'Notes']),
      attendees: attendees,
      attendeeCount: _int(j, ['attendeeCount', 'AttendeeCount'], attendees.length),
      demoCount: _int(j, ['demoCount', 'DemoCount']),
      leadCount: _int(j, ['leadCount', 'LeadCount', 'interestCount']),
      createdAt: _date(j, ['createdAt', 'CreatedAt', 'createdOn']),
      createdBy: _str(j, ['createdByName', 'CreatedByName', 'createdBy', 'CreatedBy', 'userName']),
      createdById: _str(j, ['createdById', 'CreatedById', 'createdByUserId', 'userId', 'UserId']),
    );
  }

  /// True when the signed-in user created this exhibition: matched by user
  /// id when the API sends one, otherwise by name (case and spaces ignored).
  bool isCreatedBy({required String userId, required String userName}) =>
      _isCreator(createdBy, createdById, userId: userId, userName: userName);

  /// "Venue, City" — the city is left out when it repeats the venue
  /// (e.g. "Bengaluru, Bengaluru" or "BIEC, Bengaluru, Bengaluru").
  String get place {
    final v = venue.trim();
    final c = city.trim();
    if (v.isEmpty) return c;
    if (c.isEmpty || v.toLowerCase().contains(c.toLowerCase())) return v;
    return '$v, $c';
  }
}

/// Body for POST /api/mobile/exhibitions.
class CreateExhibitionRequest {
  final String name;
  final String venue;
  final String city;
  final DateTime? startDate;
  final DateTime? endDate;
  final ExhibitionStatus status;
  final String notes;
  final List<Attendee> attendees;

  const CreateExhibitionRequest({
    required this.name,
    this.venue = '',
    this.city = '',
    this.startDate,
    this.endDate,
    this.status = ExhibitionStatus.active,
    this.notes = '',
    this.attendees = const [],
  });

  static String? _d(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'name': name,
        'venue': venue,
        'city': city,
        'startDate': _d(startDate),
        'endDate': _d(endDate),
        'status': status.apiValue,
        'notes': notes,
        'attendees': attendees.map((a) => a.toJson()).toList(),
      };
}

enum CallStatus { queued, ringing, calling, answered, completed, failed }

CallStatus parseCallStatus(String s) {
  final v = s.toLowerCase();
  if (v.contains('fail') || v.contains('busy') || v.contains('no answer') || v.contains('error')) {
    return CallStatus.failed;
  }
  if (v.contains('ring')) return CallStatus.ringing;
  if (v.contains('call') || v.contains('progress') || v.contains('dial')) return CallStatus.calling;
  if (v.contains('answer')) return CallStatus.answered;
  if (v.contains('complete') || v.contains('success') || v.contains('done')) return CallStatus.completed;
  return CallStatus.queued;
}

extension CallStatusX on CallStatus {
  String get label => switch (this) {
        CallStatus.queued => 'Queued',
        CallStatus.ringing => 'Ringing',
        CallStatus.calling => 'Calling',
        CallStatus.answered => 'Answered',
        CallStatus.completed => 'Completed',
        CallStatus.failed => 'Failed',
      };
}

class DemoRecipient {
  final String number;
  final bool isTeam;
  final String name;
  final CallStatus status;

  const DemoRecipient({
    required this.number,
    required this.isTeam,
    this.name = '',
    this.status = CallStatus.queued,
  });

  factory DemoRecipient.fromJson(Map<String, dynamic> j) => DemoRecipient(
        number: normalizeIndianMobile(
            _str(j, ['number', 'Number', 'mobile', 'mobileNumber', 'phone'])),
        isTeam: _str(j, ['type', 'Type', 'recipientType']).toLowerCase().contains('team') ||
            _pick(j, ['isTeam', 'IsTeam']) == true,
        name: _str(j, ['name', 'Name', 'attendeeName']),
        status: parseCallStatus(_str(j, ['status', 'Status', 'callStatus'], 'queued')),
      );
}

class ExhibitionDemo {
  final String id;
  final String visitorName;
  final int recipientCount;
  final CallStatus status;
  final String audioUrl;
  final String createdBy;
  final DateTime? createdAt;
  final List<DemoRecipient> recipients;
  final bool hasLead;

  const ExhibitionDemo({
    required this.id,
    this.visitorName = '',
    this.recipientCount = 0,
    this.status = CallStatus.queued,
    this.audioUrl = '',
    this.createdBy = '',
    this.createdAt,
    this.recipients = const [],
    this.hasLead = false,
  });

  factory ExhibitionDemo.fromJson(Map<String, dynamic> j) {
    final recipients = _maps(_pick(j, ['recipients', 'Recipients', 'calls']))
        .map(DemoRecipient.fromJson)
        .toList();
    final lead = _pick(j, ['hasLead', 'HasLead', 'interestCaptured', 'leadCaptured']);
    return ExhibitionDemo(
      id: _str(j, ['id', 'Id', 'demoId', 'DemoId', '_id']),
      visitorName: _str(j, ['visitorName', 'VisitorName']),
      recipientCount: _int(j, ['recipientCount', 'RecipientCount'], recipients.length),
      status: parseCallStatus(_str(j, ['status', 'Status'], 'queued')),
      audioUrl: _str(j, ['audioUrl', 'AudioUrl', 'voiceUrl', 'fileUrl']),
      createdBy: _str(j, ['createdByName', 'createdBy', 'CreatedBy', 'userName']),
      createdAt: _date(j, ['createdAt', 'CreatedAt', 'createdOn']),
      recipients: recipients,
      hasLead: lead == true || lead == 1 || lead.toString() == 'true',
    );
  }

  String get displayName => visitorName.trim().isEmpty ? 'Unnamed visitor' : visitorName.trim();

  String? get firstVisitorNumber {
    for (final r in recipients) {
      if (!r.isTeam && r.number.isNotEmpty) return r.number;
    }
    return null;
  }
}

/// How keen the school is, chosen when the lead is captured.
enum InterestLevel { hot, warm, cold }

InterestLevel? parseInterestLevel(String s) {
  final v = s.trim().toLowerCase();
  if (v.startsWith('hot') || v == 'high' || v == 'good') return InterestLevel.hot;
  if (v.startsWith('warm') || v == 'medium' || v == 'average') return InterestLevel.warm;
  if (v.startsWith('cold') || v == 'low') return InterestLevel.cold;
  return null;
}

extension InterestLevelX on InterestLevel {
  String get label => switch (this) {
        InterestLevel.hot => 'Good',
        InterestLevel.warm => 'Average',
        InterestLevel.cold => 'Low',
      };
  String get apiValue => name;
}

/// Matches the signed-in user against a record's creator: by user id when
/// the API sends one, otherwise by name (case and extra spaces ignored).
bool _isCreator(String byName, String byId, {required String userId, required String userName}) {
  String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  // The "createdBy" field sometimes carries the id itself.
  final ids = {byId.trim(), if (RegExp(r'^\d+$').hasMatch(byName.trim())) byName.trim()}
    ..remove('');
  if (ids.isNotEmpty && userId.trim().isNotEmpty && ids.contains(userId.trim())) return true;
  final by = norm(byName);
  return by.isNotEmpty && by == norm(userName);
}

class ExhibitionLead {
  final String id;
  final String schoolName;
  final String city;
  final String contactName;
  final String contactNumber;
  final String contactEmail;
  final String notes;
  final String capturedBy;
  final DateTime? createdAt;
  final String demoId;
  final String demoVisitorName;
  final InterestLevel? interestLevel;
  final String capturedById;

  const ExhibitionLead({
    required this.id,
    required this.schoolName,
    this.city = '',
    this.contactName = '',
    this.contactNumber = '',
    this.contactEmail = '',
    this.notes = '',
    this.capturedBy = '',
    this.createdAt,
    this.demoId = '',
    this.demoVisitorName = '',
    this.interestLevel,
    this.capturedById = '',
  });

  bool isCreatedBy({required String userId, required String userName}) =>
      _isCreator(capturedBy, capturedById, userId: userId, userName: userName);

  factory ExhibitionLead.fromJson(Map<String, dynamic> j) => ExhibitionLead(
        id: _str(j, ['id', 'Id', 'leadId', 'interestId', '_id']),
        schoolName: _str(j, ['schoolName', 'SchoolName']),
        city: _str(j, ['city', 'City']),
        contactName: _str(j, ['contactName', 'ContactName']),
        contactNumber: normalizeIndianMobile(
            _str(j, ['contactNumber', 'ContactNumber', 'contactMobile', 'phone'])),
        contactEmail: _str(j, ['contactEmail', 'ContactEmail', 'email']),
        notes: _str(j, ['notes', 'Notes']),
        capturedBy: _str(j, ['createdByName', 'capturedBy', 'createdBy', 'CreatedBy']),
        capturedById: _str(j, ['createdById', 'CreatedById', 'capturedById', 'createdByUserId', 'userId']),
        createdAt: _date(j, ['createdAt', 'CreatedAt', 'createdOn']),
        demoId: _str(j, ['demoId', 'DemoId']),
        demoVisitorName: _str(j, ['visitorName', 'demoVisitorName', 'VisitorName']),
        interestLevel: parseInterestLevel(
            _str(j, ['interestLevel', 'InterestLevel', 'level', 'leadLevel'])),
      );
}

/// Body for POST /api/mobile/exhibitions/demos/:demoId/interest.
class CaptureLeadRequest {
  final String schoolName;
  final String city;
  final String contactName;
  final String contactNumber;
  final String contactEmail;
  final String notes;
  final InterestLevel interestLevel;

  const CaptureLeadRequest({
    required this.schoolName,
    this.city = '',
    this.contactName = '',
    this.contactNumber = '',
    this.contactEmail = '',
    this.notes = '',
    this.interestLevel = InterestLevel.warm,
  });

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'city': city,
        'contactName': contactName,
        'contactNumber': contactNumber,
        'contactEmail': contactEmail,
        'notes': notes,
        'interestLevel': interestLevel.apiValue,
      };
}

/// A pre-recorded demo voice. Sent to the backend as `audioUrl`.
class DemoTemplate {
  final String id;
  final String title;
  final String description;
  final Duration duration;
  final String audioUrl;
  final String createdBy;
  final String createdById;

  const DemoTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.audioUrl,
    this.createdBy = '',
    this.createdById = '',
  });

  /// From GET /exhibitions/templates.
  factory DemoTemplate.fromJson(Map<String, dynamic> j) => DemoTemplate(
        id: _str(j, ['id', 'Id', 'templateId', '_id']),
        title: _str(j, ['title', 'Title', 'name', 'Name']),
        description: _str(j, ['description', 'Description']),
        duration: Duration(seconds: _int(j, ['durationSeconds', 'duration', 'Duration'])),
        audioUrl: _str(j, ['audioUrl', 'AudioUrl', 'fileUrl', 'url']),
        createdBy: _str(j, ['createdByName', 'CreatedByName', 'createdBy', 'CreatedBy']),
        createdById: _str(j, ['createdById', 'CreatedById', 'createdByUserId', 'userId']),
      );

  bool isCreatedBy({required String userId, required String userName}) =>
      _isCreator(createdBy, createdById, userId: userId, userName: userName);
}
