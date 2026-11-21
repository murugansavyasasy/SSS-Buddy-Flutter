import 'package:flutter/material.dart';

/// Text and data for the School Chimes showcase shown to visitors at the
/// exhibition stall. Edit the words here; the screen reads everything from
/// this file.
///
/// Sources: schoolchimes.com (title and description; About page: story,
/// mission and milestones: founded 2002 as Voice Snap, 15+ years with
/// schools, 3,500+ schools, 2.1M+ students, 700K+ teachers, Asia and
/// Africa) and the module names of the School Chimes ERP itself.
/// Keep claims to what the product really does.

// Brand colours (from the School Chimes logo).
const scIndigo = Color(0xFF372A8A);
const scIndigoDeep = Color(0xFF231A5E);
const scCoral = Color(0xFFF2474F);
const scYellow = Color(0xFFF4B95A);
const scSoft = Color(0xFFF6F4FF);
const scInk = Color(0xFF1C1837);
const scMuted = Color(0xFF6A6788);

const scLogoAsset = 'assets/images/schoolchimes_logo.png';

/// Home page hero (schoolchimes.com), shown on the first slide.
const scHeroBadge = 'AI-enabled school ERP trusted by 3,500+ schools';
const scHeadline = 'Simplify school management\nwith one smart platform';
const scHeroText =
    'School Chimes is the school ERP software and school communication platform built for India. '
    'Run admissions, fees, attendance, exams and reports in one place, and reach every parent by '
    'voice call, SMS, WhatsApp and app in their own language.';
/// Company description from the About page, two short lines.
const scAbout = <String>[
  'We began with voice calls that reach every parent in their own language, even on a basic phone.',
  'Today School Chimes is a complete ERP and communication platform for admissions, fees, attendance, exams, transport and more.',
];

/// Big numbers on the first slide.
const scStats = <(String, String)>[
  ('3,500+', 'schools served'),
  ('2.1M+', 'students reached'),
  ('15+ years', 'working with schools'),
];

class ScModule {
  final IconData icon;
  final String title;
  final String line;
  final List<String> points;
  final Color color;
  const ScModule(this.icon, this.title, this.line, this.points, this.color);
}

/// ERP modules (tap a tile on the showcase to see its points).
const scModules = <ScModule>[
  ScModule(Icons.school_rounded, 'Students', 'Every student, one profile', [
    'Admission to leaving: details, documents and siblings in one profile',
    'Student roll, siblings and class-wise reports',
    'Certificates generated from the student record',
  ], Color(0xFF372A8A)),
  ScModule(Icons.how_to_reg_rounded, 'Admissions', 'Enquiry to admission', [
    'Track every pre-admission enquiry',
    'Set up admission and pre-joining fees',
    'Turn an enquiry into a student in a few taps',
  ], Color(0xFF6C4BD8)),
  ScModule(Icons.fact_check_rounded, 'Attendance', 'Students and staff', [
    'Mark student and staff attendance quickly',
    'Parents know when their child is absent',
    'Attendance reports by class, day and month',
  ], Color(0xFF1E9E6A)),
  ScModule(Icons.currency_rupee_rounded, 'Fees', 'Collect and track fees', [
    'Fee structure by class, group and discount',
    'Advance, pending and consolidated fee reports',
    'Clear view of every rupee collected',
  ], Color(0xFFF2474F)),
  ScModule(Icons.assignment_rounded, 'Exams', 'Exams and progress cards', [
    'Exams and class tests in one place',
    'Progress cards ready for parents',
    'Academic health report for every class',
  ], Color(0xFFE08A00)),
  ScModule(Icons.menu_book_rounded, 'Homework', 'Homework and lesson plans', [
    'Homework reaches parents the same day',
    'Lesson plans tracked for every teacher',
    'Reports on what was taught and given',
  ], Color(0xFF0E8FB5)),
  ScModule(Icons.record_voice_over_rounded, 'Voice calls', 'Parents hear the school', [
    'Send a recorded voice message to every parent',
    'See who answered and who missed the call',
    'Parents can call back with a request',
  ], Color(0xFFF2474F)),
  ScModule(Icons.campaign_rounded, 'Messages', 'Circulars and events', [
    'Circulars, events and announcements to parents',
    'Parent-teacher meetings planned and recorded',
    'Communication reports for the management',
  ], Color(0xFF372A8A)),
  ScModule(Icons.calendar_view_week_rounded, 'Timetable', 'Class and teacher timetables', [
    'Build class and teacher timetables',
    'Avoid clashes for teachers and rooms',
    'Everyone sees the same schedule',
  ], Color(0xFF6C4BD8)),
  ScModule(Icons.directions_bus_rounded, 'Transport', 'Vehicles and routes', [
    'Manage vehicles, routes and stops',
    'Know which student takes which bus',
    'Transport fees in the same system',
  ], Color(0xFFE08A00)),
  ScModule(Icons.bed_rounded, 'Hostel', 'Rooms and boarders', [
    'Rooms, beds and boarders in one list',
    'Hostel fees with the rest of the fees',
    'Hostel reports when you need them',
  ], Color(0xFF1E9E6A)),
  ScModule(Icons.local_library_rounded, 'Library', 'Books and lending', [
    'Catalogue every book',
    'Issue and return in seconds',
    'Books report at the end of the term',
  ], Color(0xFF0E8FB5)),
  ScModule(Icons.badge_rounded, 'Staff & payroll', 'People and salaries', [
    'Staff profiles and attendance',
    'Payroll prepared from attendance',
    'Payroll reports for accounts',
  ], Color(0xFF372A8A)),
  ScModule(Icons.inventory_2_rounded, 'Inventory', 'Stock and stores', [
    'Track school stock and stores',
    'Allocate budget to staff members',
    'Know what was issued and to whom',
  ], Color(0xFF6A6788)),
  ScModule(Icons.workspace_premium_rounded, 'Certificates', 'Ready in a click', [
    'Transfer, bonafide and other certificates',
    'Filled in from the student record',
    'Consistent, printable format',
  ], Color(0xFFE08A00)),
  ScModule(Icons.person_pin_rounded, 'Visitors', 'Gate and front office', [
    'Record every visitor at the gate',
    'Know who came, when and why',
    'Visitor reports for safety',
  ], Color(0xFF6C4BD8)),
  ScModule(Icons.forum_rounded, 'Parent concerns', 'Listen and resolve', [
    'Parents raise a concern from the app',
    'The right staff member follows it up',
    'Nothing gets lost in a phone call',
  ], Color(0xFFF2474F)),
  ScModule(Icons.insights_rounded, 'Reports', 'Dashboards for management', [
    'School dashboard at a glance',
    'Fee, attendance, academic and usage reports',
    'Decisions based on real numbers',
  ], Color(0xFF1E9E6A)),
];

/// "Built for everyone in the school".
const scRoles = <(IconData, String, String)>[
  (Icons.account_balance_rounded, 'Management', 'Dashboards, fee collection and reports for the whole school.'),
  (Icons.school_rounded, 'Principal', 'Attendance, exams and academic health of every class.'),
  (Icons.co_present_rounded, 'Teachers', 'Attendance, homework, lesson plans and marks in minutes.'),
  (Icons.family_restroom_rounded, 'Parents', 'Voice calls, homework, progress cards and fee updates.'),
  (Icons.calculate_rounded, 'Office & accounts', 'Fees, payroll, inventory and certificates without paperwork.'),
];

/// "Why schools choose School Chimes".
const scWhy = <(IconData, String, String)>[
  (Icons.hub_rounded, 'One platform', 'Fees, attendance, exams, reports and communication in one system. No more juggling apps and registers.'),
  (Icons.auto_awesome_rounded, 'AI-enabled', 'A smart ERP that does the routine work, so staff spend time on students.'),
  (Icons.record_voice_over_rounded, 'Parents actually hear you', 'Voice calls reach every parent, even those who don\'t read messages.'),
  (Icons.verified_rounded, 'Trusted', '3,500+ schools, 2.1 million students and 700,000 teachers across Asia and Africa use our platforms.'),
];

// ─────────────────────────────────────────────────────────────────────────
// Spotlights: one main solution per Give Demo / Capture Lead step, so the
// visitor learns about School Chimes while their details are entered.
// ─────────────────────────────────────────────────────────────────────────

class ScSpotlight {
  final IconData icon;
  final Color color;

  /// Small label, e.g. "Communication".
  final String kicker;
  final String headline;
  final String line;
  final List<(IconData, String)> points;

  const ScSpotlight({
    required this.icon,
    required this.color,
    required this.kicker,
    required this.headline,
    required this.line,
    required this.points,
  });
}

const scSpotCommunication = ScSpotlight(
  icon: Icons.record_voice_over_rounded,
  color: scCoral,
  kicker: 'Communication',
  headline: 'Every parent hears the school',
  line: 'The demo call you are about to get is how schools reach parents with School Chimes.',
  points: [
    (Icons.mic_rounded, 'Record once, every parent gets a voice call'),
    (Icons.call_received_rounded, 'See who answered and who missed it'),
    (Icons.campaign_rounded, 'Circulars, events and homework alongside'),
  ],
);

const scSpotExams = ScSpotlight(
  icon: Icons.assignment_rounded,
  color: Color(0xFFE08A00),
  kicker: 'Examination',
  headline: 'Exams to progress cards, in one flow',
  line: 'Marks go in once; reports and progress cards come out ready.',
  points: [
    (Icons.edit_note_rounded, 'Exams and class tests set up for every class'),
    (Icons.description_rounded, 'Progress cards ready to share with parents'),
    (Icons.monitor_heart_rounded, 'Academic health report for each class'),
  ],
);

const scSpotFees = ScSpotlight(
  icon: Icons.currency_rupee_rounded,
  color: Color(0xFF1E9E6A),
  kicker: 'Fees',
  headline: 'Know every rupee, every day',
  line: 'Fee structures, collection and dues, without a single register.',
  points: [
    (Icons.account_tree_rounded, 'Fee structure by class, group and discount'),
    (Icons.receipt_long_rounded, 'Advance, pending and consolidated reports'),
    (Icons.query_stats_rounded, 'Collection tracked class by class'),
  ],
);

const scSpotAdmissions = ScSpotlight(
  icon: Icons.how_to_reg_rounded,
  color: Color(0xFF6C4BD8),
  kicker: 'Admissions',
  headline: 'From enquiry to admission',
  line: 'Just like this lead, every admission enquiry is tracked till it joins.',
  points: [
    (Icons.contact_phone_rounded, 'Every pre-admission enquiry recorded'),
    (Icons.payments_rounded, 'Admission and pre-joining fees set up'),
    (Icons.person_add_alt_1_rounded, 'Enquiry becomes a student in a few taps'),
  ],
);

const scSpotAttendance = ScSpotlight(
  icon: Icons.fact_check_rounded,
  color: Color(0xFF0E8FB5),
  kicker: 'Attendance',
  headline: 'Attendance in minutes, not periods',
  line: 'Students and staff marked fast, and parents know the same day.',
  points: [
    (Icons.checklist_rounded, 'Student and staff attendance in one place'),
    (Icons.sms_rounded, 'Parents informed when their child is absent'),
    (Icons.bar_chart_rounded, 'Reports by class, day and month'),
  ],
);

const scSpotParents = ScSpotlight(
  icon: Icons.family_restroom_rounded,
  color: scIndigo,
  kicker: 'Parent connect',
  headline: 'Parents stay in the loop',
  line: 'Homework, messages and concerns: parents and teachers on the same page.',
  points: [
    (Icons.menu_book_rounded, 'Homework reaches parents the same day'),
    (Icons.forum_rounded, 'Parents raise concerns, the school resolves them'),
    (Icons.groups_rounded, 'Parent-teacher meetings planned and recorded'),
  ],
);

const scSpotReports = ScSpotlight(
  icon: Icons.insights_rounded,
  color: Color(0xFF1E9E6A),
  kicker: 'Reports',
  headline: 'Your whole school on one screen',
  line: 'Dashboards and reports for the management, always up to date.',
  points: [
    (Icons.dashboard_rounded, 'School dashboard at a glance'),
    (Icons.query_stats_rounded, 'Fee, attendance, academic and usage reports'),
    (Icons.auto_awesome_rounded, 'AI-enabled: routine work done for you'),
  ],
);

const scSpotWhy = ScSpotlight(
  icon: Icons.verified_rounded,
  color: scCoral,
  kicker: 'School Chimes',
  headline: 'Trusted by 3,500+ schools',
  line: 'The AI-enabled ERP. One smart platform, working with schools for 15+ years.',
  points: [
    (Icons.hub_rounded, 'Fees, attendance, exams, reports and communication together'),
    (Icons.record_voice_over_rounded, 'Voice calls parents actually hear'),
    (Icons.support_agent_rounded, 'Our team sets it up with your school\'s data'),
  ],
);

/// Give Demo steps: Voice → Visitor → Review.
const scGiveDemoSpotlights = [scSpotCommunication, scSpotExams, scSpotFees];

/// Capture Lead steps: School → Interest → Contact → Notes → Review.
const scCaptureLeadSpotlights = [scSpotAdmissions, scSpotAttendance, scSpotParents, scSpotReports, scSpotWhy];
