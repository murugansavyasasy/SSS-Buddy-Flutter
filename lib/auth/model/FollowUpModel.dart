import 'package:flutter/material.dart';

enum FollowUpType {
  call('Call', Icons.call_rounded, Color(0xFF2E7D6B)),
  visit('Visit', Icons.place_rounded, Color(0xFF4F6693)),
  demo('Demo', Icons.co_present_rounded, Color(0xFF7B5EA7)),
  payment('Payment', Icons.currency_rupee_rounded, Color(0xFFB5651D)),
  renewal('Renewal', Icons.autorenew_rounded, Color(0xFF2C7DA0)),
  other('Other', Icons.more_horiz_rounded, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;

  const FollowUpType(this.label, this.icon, this.color);

  static FollowUpType from(String? v) =>
      values.firstWhere((t) => t.name == v, orElse: () => FollowUpType.other);
}

enum FollowUpStatus { pending, done, cancelled }

/// Minutes before [FollowUp.dueAt] to remind; -1 = no reminder.
const followUpReminderOptions = <int, String>{
  0: 'At time',
  15: '15 min before',
  60: '1 hour before',
  1440: '1 day before',
  -1: 'No reminder',
};

class FollowUp {
  final String id;
  final String ownerId;
  final String ownerName;
  final String schoolId;
  final String schoolName;
  final String contactName;
  final String contactPhone;
  final FollowUpType type;
  final DateTime dueAt;
  final int remindBefore;
  final String note;
  final FollowUpStatus status;
  final String outcome;
  final String demoId;
  final DateTime? completedAt;

  const FollowUp({
    this.id = '',
    required this.ownerId,
    required this.ownerName,
    this.schoolId = '',
    required this.schoolName,
    this.contactName = '',
    this.contactPhone = '',
    required this.type,
    required this.dueAt,
    this.remindBefore = 15,
    this.note = '',
    this.status = FollowUpStatus.pending,
    this.outcome = '',
    this.demoId = '',
    this.completedAt,
  });

  bool get isPending => status == FollowUpStatus.pending;

  bool get isOverdue => isPending && dueAt.isBefore(DateTime.now());

  bool get isToday {
    final n = DateTime.now();
    return dueAt.year == n.year && dueAt.month == n.month && dueAt.day == n.day;
  }

  DateTime? get remindAt =>
      remindBefore < 0 ? null : dueAt.subtract(Duration(minutes: remindBefore));

  FollowUp copyWith({
    String? schoolId,
    String? schoolName,
    String? contactName,
    String? contactPhone,
    FollowUpType? type,
    DateTime? dueAt,
    int? remindBefore,
    String? note,
    FollowUpStatus? status,
    String? outcome,
    DateTime? completedAt,
  }) =>
      FollowUp(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName,
        schoolId: schoolId ?? this.schoolId,
        schoolName: schoolName ?? this.schoolName,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        type: type ?? this.type,
        dueAt: dueAt ?? this.dueAt,
        remindBefore: remindBefore ?? this.remindBefore,
        note: note ?? this.note,
        status: status ?? this.status,
        outcome: outcome ?? this.outcome,
        demoId: demoId,
        completedAt: completedAt ?? this.completedAt,
      );

  FollowUp withId(String newId) => FollowUp(
        id: newId,
        ownerId: ownerId,
        ownerName: ownerName,
        schoolId: schoolId,
        schoolName: schoolName,
        contactName: contactName,
        contactPhone: contactPhone,
        type: type,
        dueAt: dueAt,
        remindBefore: remindBefore,
        note: note,
        status: status,
        outcome: outcome,
        demoId: demoId,
        completedAt: completedAt,
      );

  factory FollowUp.fromJson(Map<String, dynamic> d) {
    int ms(String k) => (d[k] as num?)?.toInt() ?? 0;
    return FollowUp(
      id: d['id']?.toString() ?? '',
      ownerId: d['ownerId']?.toString() ?? '',
      ownerName: d['ownerName']?.toString() ?? '',
      schoolId: d['schoolId']?.toString() ?? '',
      schoolName: d['schoolName']?.toString() ?? '',
      contactName: d['contactName']?.toString() ?? '',
      contactPhone: d['contactPhone']?.toString() ?? '',
      type: FollowUpType.from(d['type']?.toString()),
      dueAt: DateTime.fromMillisecondsSinceEpoch(ms('dueAt')),
      remindBefore: (d['remindBefore'] as num?)?.toInt() ?? -1,
      note: d['note']?.toString() ?? '',
      status: FollowUpStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => FollowUpStatus.pending,
      ),
      outcome: d['outcome']?.toString() ?? '',
      demoId: d['demoId']?.toString() ?? '',
      completedAt: ms('completedAt') == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms('completedAt')),
    );
  }

  /// Field names are plain JSON so the same shape can be sent to a backend
  /// API (or Firestore) later.
  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'schoolId': schoolId,
        'schoolName': schoolName,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'type': type.name,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'remindBefore': remindBefore,
        'note': note,
        'status': status.name,
        'outcome': outcome,
        'demoId': demoId,
        'completedAt': completedAt?.millisecondsSinceEpoch ?? 0,
      };
}

/// Pre-filled values when opening the form from another screen (e.g. a demo).
class FollowUpFormArgs {
  final FollowUp? existing;
  final String schoolId;
  final String schoolName;
  final String contactPhone;
  final String demoId;
  final FollowUpType? type;

  const FollowUpFormArgs({
    this.existing,
    this.schoolId = '',
    this.schoolName = '',
    this.contactPhone = '',
    this.demoId = '',
    this.type,
  });
}
