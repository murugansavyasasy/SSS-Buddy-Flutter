import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_common.dart';

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder, {bool full = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxWidth: 680),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => full
          ? FractionallySizedBox(heightFactor: 0.92, child: builder(ctx))
          : builder(ctx),
    );

// MARK: - Demo sent: success + "capture a lead?"

/// Shows the success check, then asks whether to capture a lead.
/// Returns true for "Yes, capture lead"; false / null for Skip or swipe down.
Future<bool> showDemoSentSheet(BuildContext context, {required int callCount}) async {
  final yes = await _showSheet<bool>(
    context,
    (ctx) => _DemoSentSheet(callCount: callCount),
  );
  return yes == true;
}

class _DemoSentSheet extends StatelessWidget {
  final int callCount;
  const _DemoSentSheet({required this.callCount});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.25), spreadRadius: 10),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Demo call initiated',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: exInk)),
            const SizedBox(height: 4),
            Text('$callCount ${callCount == 1 ? 'call' : 'calls'} queued',
                style: const TextStyle(fontSize: 14, color: exSubtle)),
            const SizedBox(height: 20),
            const Divider(height: 1, color: exBorder),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Did the visitor like the demo?',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: exInk)),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Capture this school as a lead?',
                  style: TextStyle(fontSize: 15, color: exSubtle)),
            ),
            const SizedBox(height: 18),
            ExPrimaryButton(
              label: 'Yes, capture lead',
              icon: Icons.star_rounded,
              height: 56,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ExSecondaryButton(
                label: 'Skip',
                height: 56,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      );
}

Widget _handle() => Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: exStrongBorder,
        borderRadius: BorderRadius.circular(3),
      ),
    );

// MARK: - Capture lead

/// Capture Lead form. With [demo] the lead is linked to that demo; without it
/// the lead is standalone for the exhibition. Returns true when saved.
Future<bool> showCaptureLeadSheet(
  BuildContext context, {
  required String exhibitionId,
  ExhibitionDemo? demo,
  String? prefillContact,
  String? prefillNumber,
}) async {
  final saved = await _showSheet<bool>(
    context,
    (ctx) => _CaptureLeadSheet(
      exhibitionId: exhibitionId,
      demo: demo,
      prefillContact: prefillContact ?? demo?.visitorName,
      prefillNumber: prefillNumber ?? demo?.firstVisitorNumber,
    ),
    full: true,
  );
  return saved == true;
}

class _CaptureLeadSheet extends ConsumerStatefulWidget {
  final String exhibitionId;
  final ExhibitionDemo? demo;
  final String? prefillContact;
  final String? prefillNumber;

  const _CaptureLeadSheet({
    required this.exhibitionId,
    this.demo,
    this.prefillContact,
    this.prefillNumber,
  });

  @override
  ConsumerState<_CaptureLeadSheet> createState() => _CaptureLeadSheetState();
}

class _CaptureLeadSheetState extends ConsumerState<_CaptureLeadSheet> {
  late final _school = TextEditingController();
  late final _city = TextEditingController();
  late final _contact = TextEditingController(text: widget.prefillContact ?? '');
  late final _number = TextEditingController(text: widget.prefillNumber ?? '');
  late final _email = TextEditingController();
  late final _notes = TextEditingController();
  bool _tried = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_school, _city, _contact, _number, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _numberError {
    final n = _number.text.trim();
    if (!_tried || n.isEmpty) return null;
    return isValidIndianMobile(normalizeIndianMobile(n)) ? null : 'Enter a 10-digit number';
  }

  String? get _emailError {
    final e = _email.text.trim();
    if (!_tried || e.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e) ? null : 'Enter a valid email';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _error = null;
    });
    if (_school.text.trim().isEmpty || _numberError != null || _emailError != null) return;
    setState(() => _saving = true);
    try {
      await ref.read(exhibitionRepositoryProvider).captureLead(
            exhibitionId: widget.exhibitionId,
            demoId: widget.demo?.id,
            req: CaptureLeadRequest(
              schoolName: _school.text.trim(),
              city: _city.text.trim(),
              contactName: _contact.text.trim(),
              contactNumber: normalizeIndianMobile(_number.text.trim()),
              contactEmail: _email.text.trim(),
              notes: _notes.text.trim(),
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  static const _quickNotes = [
    'Wants a demo visit',
    'Send brochure',
    'Call back later',
    'Asked for pricing',
    'Decision maker',
  ];

  void _addQuickNote(String n) {
    HapticFeedback.selectionClick();
    final cur = _notes.text.trim();
    if (cur.toLowerCase().contains(n.toLowerCase())) return;
    setState(() => _notes.text = cur.isEmpty ? n : '$cur. $n');
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final schoolError = _tried && _school.text.trim().isEmpty ? 'School name is required' : null;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final base = AppColors.primary;

    Widget pair(Widget a, Widget b) => wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
          )
        : Column(children: [a, const SizedBox(height: 14), b]);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        color: exPageBg,
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
              child: Column(
                children: [
                  _handle(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Capture lead',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: exInk,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  demo == null ? Icons.storefront_rounded : Icons.link_rounded,
                                  size: 15,
                                  color: demo == null ? const Color(0xFFB45309) : base,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    demo == null
                                        ? 'Standalone lead for this exhibition'
                                        : 'Linked to demo · ${demo.displayName}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: demo == null ? const Color(0xFFB45309) : base,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        style: IconButton.styleFrom(backgroundColor: exPageBg),
                        icon: const Icon(Icons.close_rounded, color: exInk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: exBorder),
            // ── Form ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _LeadSection(
                    icon: Icons.school_rounded,
                    title: 'School',
                    children: [
                      pair(
                        ExField(
                          label: 'School name',
                          required: true,
                          controller: _school,
                          hint: 'e.g. Green Valley Public School',
                          prefixIcon: Icons.apartment_rounded,
                          errorText: schoolError,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) {
                            if (_tried) setState(() {});
                          },
                        ),
                        ExField(
                          label: 'City',
                          controller: _city,
                          hint: 'e.g. Chennai',
                          prefixIcon: Icons.place_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LeadSection(
                    icon: Icons.person_rounded,
                    title: 'Contact person',
                    children: [
                      ExField(
                        label: 'Contact name',
                        controller: _contact,
                        hint: 'Name and role',
                        prefixIcon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      pair(
                        ExField(
                          label: 'Contact number',
                          controller: _number,
                          hint: '10-digit mobile',
                          prefixText: '+91  ',
                          keyboardType: TextInputType.phone,
                          errorText: _numberError,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        ExField(
                          label: 'Contact email',
                          controller: _email,
                          hint: 'name@school.edu.in',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          textCapitalization: TextCapitalization.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LeadSection(
                    icon: Icons.sticky_note_2_rounded,
                    title: 'Notes',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final n in _quickNotes)
                            ActionChip(
                              avatar: Icon(Icons.add_rounded, size: 16, color: base),
                              label: Text(n),
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: exInk,
                              ),
                              backgroundColor: exPageBg,
                              side: const BorderSide(color: exBorder),
                              shape: const StadiumBorder(),
                              onPressed: () => _addQuickNote(n),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notes,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 16, color: exInk),
                        decoration: exInputDecoration(
                          hint: 'e.g. Wants a full product walkthrough',
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: exDanger.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: exDanger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: exDanger, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Footer ──
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SafeArea(
                top: false,
                child: ExPrimaryButton(
                  label: 'Save Lead',
                  icon: Icons.check_rounded,
                  height: 56,
                  loadingLabel: 'Saving…',
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card grouping a few lead fields under an icon title.
class _LeadSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _LeadSection({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: exBorder),
          boxShadow: exCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: exTint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: exInk,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
}

// MARK: - Demo detail

/// Recipients, call statuses and the voice of one demo.
/// Returns true when the user asked to capture a lead for it.
Future<bool> showDemoDetailSheet(BuildContext context, ExhibitionDemo demo) async {
  final capture = await _showSheet<bool>(
    context,
    (ctx) => _DemoDetailSheet(demo: demo),
    full: true,
  );
  return capture == true;
}

class _DemoDetailSheet extends StatefulWidget {
  final ExhibitionDemo demo;
  const _DemoDetailSheet({required this.demo});

  @override
  State<_DemoDetailSheet> createState() => _DemoDetailSheetState();
}

class _DemoDetailSheetState extends State<_DemoDetailSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.demo.audioUrl;
    if (url.isEmpty) {
      exToast(context, 'No audio available for this demo', error: true);
      return;
    }
    if (_player.playing) {
      await _player.pause();
      return;
    }
    try {
      if (_player.audioSource == null) {
        setState(() => _loading = true);
        await _player.setUrl(url);
        if (mounted) setState(() => _loading = false);
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        exToast(context, 'Could not play audio', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demo;
    final (bg, fg) = callStatusColors(d.status);
    return Column(
      children: [
        const SizedBox(height: 10),
        _handle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text('Demo details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exSubtle)),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(d.displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: exInk)),
                  ExPill(label: d.status.label, background: bg, foreground: fg),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (d.createdBy.isNotEmpty) 'Created by ${d.createdBy}',
                  if (d.createdAt != null) exWhen(d.createdAt),
                ].join(' · '),
                style: const TextStyle(fontSize: 14, color: exSubtle),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: exPageBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (_, snap) {
                    final playing = snap.data?.playing ?? false;
                    return Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: exInk),
                            tooltip: playing ? 'Pause' : 'Play voice',
                            onPressed: _toggle,
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<Duration>(
                            stream: _player.positionStream,
                            builder: (_, pos) {
                              final total = _player.duration ?? Duration.zero;
                              final p = pos.data ?? Duration.zero;
                              final f = total.inMilliseconds == 0
                                  ? 0.0
                                  : (p.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Demo voice',
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: exInk)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: f,
                                      minHeight: 4,
                                      backgroundColor: exBorder,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${exDuration(p)} / ${exDuration(total)}',
                                      style: const TextStyle(fontSize: 12, color: exSubtle)),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text('Recipients (${d.recipients.isEmpty ? d.recipientCount : d.recipients.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: exInk)),
              const SizedBox(height: 8),
              if (d.recipients.isEmpty)
                const Text('Call details are not available yet.',
                    style: TextStyle(color: exSubtle))
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: exBorder),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < d.recipients.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: exPageBg),
                        _RecipientRow(r: d.recipients[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: d.hasLead
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F7EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF1A7F3C)),
                      SizedBox(width: 10),
                      Text('Lead captured for this demo',
                          style: TextStyle(
                              color: Color(0xFF1A7F3C), fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : ExPrimaryButton(
                  label: 'Capture Lead for this demo',
                  icon: Icons.star_rounded,
                  onPressed: () => Navigator.pop(context, true),
                ),
        ),
      ],
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final DemoRecipient r;
  const _RecipientRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = callStatusColors(r.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatIndianMobile(r.number),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: exInk)),
                if (r.name.isNotEmpty)
                  Text(r.name, style: const TextStyle(fontSize: 12.5, color: exSubtle)),
              ],
            ),
          ),
          ExPill(
            label: r.isTeam ? 'Attender' : 'Visitor',
            background: r.isTeam ? const Color(0xFFE8ECF5) : const Color(0xFFECE8D2),
            foreground: exInk,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Center(child: ExPill(label: r.status.label, background: bg, foreground: fg)),
          ),
        ],
      ),
    );
  }
}
