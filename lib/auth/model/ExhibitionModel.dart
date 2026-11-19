import 'ManagementVideosModel.dart';

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

/// One demo video link sent on WhatsApp, e.g. (label: 'Tamil', url: …).
/// An empty [label] means a single unlabeled link.
typedef DemoVideoLink = ({String label, String url});

/// Languages sent to visitors, in message order, with the spellings that
/// may appear in a Management Videos name.
const demoVideoLanguages = <String, List<String>>{
  'Tamil': ['tamil'],
  'English': ['english'],
  'Hindi': ['hindi'],
  'Kannada': ['kannada', 'kanada'],
};

/// From the Management Videos list (GET api/mobile/GetVideos), the first
/// video whose name mentions each language, in [demoVideoLanguages] order.
/// Languages with no matching video are left out.
List<DemoVideoLink> pickDemoVideoLinks(List<Managementvideosmodel> videos) => [
      for (final lang in demoVideoLanguages.entries)
        for (final v in videos
            .where((v) =>
                v.videoURL.trim().isNotEmpty &&
                lang.value.any((w) => v.videoName.toLowerCase().contains(w)))
            .take(1))
          (label: lang.key, url: v.videoURL.trim()),
    ];

/// Link that opens a chat with [number] and a prefilled message carrying
/// the demo [videos]: the WhatsApp app, or WhatsApp Web in the browser when
/// [web] is true (no app installed). The user still taps Send.
Uri demoVideoWhatsAppUri({
  required String number,
  required List<DemoVideoLink> videos,
  String visitorName = '',
  String exhibitionName = '',
  bool web = false,
}) {
  final n = normalizeIndianMobile(number);
  final name = visitorName.trim();
  final event = exhibitionName.trim();
  final links = videos.where((v) => v.url.trim().isNotEmpty).toList();
  final b = StringBuffer(name.isEmpty ? 'Dear Sir/Madam' : 'Dear $name')
    ..write(', thank you for visiting us')
    ..write(event.isEmpty ? '.' : ' at $event.');
  if (links.length == 1 && links.first.label.isEmpty) {
    b.write('\nWatch our demo video: ${links.first.url.trim()}');
  } else if (links.isNotEmpty) {
    b.write('\nWatch our demo videos:');
    for (final v in links) {
      b.write('\n${v.label.isEmpty ? '' : '${v.label}: '}${v.url.trim()}');
    }
  }
  final query = 'phone=91$n&text=${Uri.encodeComponent(b.toString())}';
  return Uri.parse(web ? 'https://web.whatsapp.com/send?$query' : 'whatsapp://send?$query');
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

  /// This exhibition with every empty field filled from [other] (e.g. the
  /// detail response topped up with what the list row already had).
  Exhibition mergedWith(Exhibition other) {
    String pick(String a, String b) => a.trim().isNotEmpty ? a : b;
    return Exhibition(
      id: pick(id, other.id),
      name: pick(name, other.name),
      venue: pick(venue, other.venue),
      city: pick(city, other.city),
      startDate: startDate ?? other.startDate,
      endDate: endDate ?? other.endDate,
      status: status,
      notes: pick(notes, other.notes),
      attendees: attendees.isNotEmpty ? attendees : other.attendees,
      attendeeCount: attendeeCount > 0 ? attendeeCount : other.attendeeCount,
      demoCount: demoCount > 0 ? demoCount : other.demoCount,
      leadCount: leadCount > 0 ? leadCount : other.leadCount,
      createdAt: createdAt ?? other.createdAt,
      createdBy: pick(createdBy, other.createdBy),
      createdById: pick(createdById, other.createdById),
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

  /// Dialler error for this number (from GET /exhibitions/demos/:demoId).
  final String error;

  const DemoRecipient({
    required this.number,
    required this.isTeam,
    this.name = '',
    this.status = CallStatus.queued,
    this.error = '',
  });

  factory DemoRecipient.fromJson(Map<String, dynamic> j) => DemoRecipient(
        number: normalizeIndianMobile(
            _str(j, ['number', 'Number', 'mobile', 'mobileNumber', 'phone'])),
        isTeam: _str(j, ['type', 'Type', 'recipientType']).toLowerCase().contains('team') ||
            _pick(j, ['isTeam', 'IsTeam']) == true,
        name: _str(j, ['recipientName', 'RecipientName', 'name', 'Name', 'attendeeName']),
        status: parseCallStatus(_str(j, ['callStatus', 'CallStatus', 'status', 'Status'], 'queued')),
        error: _str(j, ['error', 'Error', 'errorMessage']),
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

  /// This list row filled in from GET /exhibitions/demos/:demoId, which has
  /// the recipients the list leaves out. Empty detail fields keep this row's.
  ExhibitionDemo mergedWith(ExhibitionDemo detail) => ExhibitionDemo(
        id: id.isNotEmpty ? id : detail.id,
        visitorName: detail.visitorName.trim().isNotEmpty ? detail.visitorName : visitorName,
        recipientCount: detail.recipients.isNotEmpty ? detail.recipients.length : recipientCount,
        status: status,
        audioUrl: detail.audioUrl.isNotEmpty ? detail.audioUrl : audioUrl,
        createdBy: createdBy.isNotEmpty ? createdBy : detail.createdBy,
        createdAt: createdAt ?? detail.createdAt,
        recipients: detail.recipients.isNotEmpty ? detail.recipients : recipients,
        hasLead: hasLead || detail.hasLead,
      );
}

/// How keen the school is, chosen when the lead is captured.
enum InterestLevel { hot, warm, cold }

InterestLevel? parseInterestLevel(String s) {
  final v = s.trim().toLowerCase();
  if (v.startsWith('hot') || v == 'high' || v == 'excellent') return InterestLevel.hot;
  if (v.startsWith('warm') || v == 'medium' || v == 'good') return InterestLevel.warm;
  if (v.startsWith('cold') || v == 'low' || v == 'average') return InterestLevel.cold;
  return null;
}

extension InterestLevelX on InterestLevel {
  String get label => switch (this) {
        InterestLevel.hot => 'Excellent',
        InterestLevel.warm => 'Good',
        InterestLevel.cold => 'Average',
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

  /// Photo / PDF URLs attached to the lead (uploaded to S3).
  final List<String> attachments;

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
    this.attachments = const [],
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
        attachments: _leadMedia(j),
      );
}

/// The lead's media: `mediaUrl` (single S3 link, current API), else an
/// `attachments` list from older responses.
List<String> _leadMedia(Map m) {
  final media = _str(m, ['mediaUrl', 'MediaUrl']).trim();
  if (media.isNotEmpty) return [media];
  return _urlList(m, ['attachments', 'Attachments', 'files', 'Files']);
}

/// URLs from a list of strings or of objects with a `url`/`fileUrl`.
List<String> _urlList(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is List) {
      return [
        for (final e in v)
          if (e is String && e.isNotEmpty)
            e
          else if (e is Map)
            _str(e, ['url', 'Url', 'fileUrl', 'FileUrl', 'link'])
      ].where((u) => u.isNotEmpty).toList();
    }
  }
  return const [];
}

/// Body for POST /api/mobile/exhibitions/demos/:demoId/interest and
/// PUT /api/mobile/exhibitions/leads/:leadId. The API keeps one media link
/// (`mediaUrl`); the PUT replaces the lead, so the current one is resent.
class CaptureLeadRequest {
  final String schoolName;
  final String city;
  final String contactName;
  final String contactNumber;
  final String contactEmail;
  final String notes;
  final InterestLevel interestLevel;

  /// S3 URLs of attached photos / PDFs.
  final List<String> attachments;

  const CaptureLeadRequest({
    required this.schoolName,
    this.city = '',
    this.contactName = '',
    this.contactNumber = '',
    this.contactEmail = '',
    this.notes = '',
    this.interestLevel = InterestLevel.warm,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'city': city,
        'contactName': contactName,
        'contactNumber': contactNumber,
        'contactEmail': contactEmail,
        'notes': notes,
        'interestLevel': interestLevel.apiValue,
        'mediaUrl': attachments.isEmpty ? '' : attachments.first,
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

  /// True for templates shared across all exhibitions (`scope: "common"`).
  final bool isCommon;

  const DemoTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.audioUrl,
    this.createdBy = '',
    this.createdById = '',
    this.isCommon = false,
  });

  DemoTemplate withDuration(Duration d) => DemoTemplate(
        id: id,
        title: title,
        description: description,
        duration: d,
        audioUrl: audioUrl,
        createdBy: createdBy,
        createdById: createdById,
        isCommon: isCommon,
      );

  /// From GET /exhibitions/:id/voice-templates.
  factory DemoTemplate.fromJson(Map<String, dynamic> j) => DemoTemplate(
        id: _str(j, ['id', 'Id', 'templateId', '_id']),
        title: _str(j, ['title', 'Title', 'name', 'Name']),
        description: _str(j, ['description', 'Description']),
        duration: Duration(seconds: _int(j, ['durationSeconds', 'duration', 'Duration'])),
        audioUrl: _str(j, ['audioUrl', 'AudioUrl', 'fileUrl', 'url']),
        createdBy: _str(j, ['createdByName', 'CreatedByName', 'createdBy', 'CreatedBy']),
        createdById: _str(j, ['createdById', 'CreatedById', 'createdByUserId', 'userId']),
        isCommon: _str(j, ['scope', 'Scope']).toLowerCase() == 'common',
      );

  bool isCreatedBy({required String userId, required String userName}) =>
      _isCreator(createdBy, createdById, userId: userId, userName: userName);
}
