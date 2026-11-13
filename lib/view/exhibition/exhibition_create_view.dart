import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'widget/exhibition_common.dart';

class _TeamRow {
  final TextEditingController name;
  final TextEditingController mobile;

  _TeamRow([Attendee? a])
      : name = TextEditingController(text: a?.name ?? ''),
        mobile = TextEditingController(text: a?.mobile ?? '');

  void dispose() {
    name.dispose();
    mobile.dispose();
  }
}

/// POST /api/mobile/exhibitions. Pops with the created [Exhibition].
/// With [initial] it edits that exhibition instead (PUT) and pops with true.
class ExhibitionCreateView extends ConsumerStatefulWidget {
  final Exhibition? initial;

  const ExhibitionCreateView({super.key, this.initial});

  @override
  ConsumerState<ExhibitionCreateView> createState() => _ExhibitionCreateViewState();
}

class _ExhibitionCreateViewState extends ConsumerState<ExhibitionCreateView> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _venue = TextEditingController(text: widget.initial?.venue ?? '');
  late final _city = TextEditingController(text: widget.initial?.city ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late DateTime? _start = widget.initial?.startDate;
  late DateTime? _end = widget.initial?.endDate;
  late final List<_TeamRow> _team = [
    for (final a in widget.initial?.attendees ?? const <Attendee>[]) _TeamRow(a),
    if ((widget.initial?.attendees ?? const []).isEmpty) _TeamRow(),
  ];

  bool get _editing => widget.initial != null;

  bool _tried = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _notes.dispose();
    for (final r in _team) {
      r.dispose();
    }
    super.dispose();
  }

  String? _rowError(_TeamRow r) {
    if (!_tried) return null;
    final m = r.mobile.text.trim();
    if (m.isNotEmpty && !isValidIndianMobile(m)) return 'Enter a 10-digit mobile number';
    if (m.isEmpty && r.name.text.trim().isNotEmpty) return 'Add a mobile number or remove this row';
    return null;
  }

  void _removeRow(_TeamRow r) {
    setState(() => _team.remove(r));
    // Dispose after the row's text fields have left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => r.dispose());
  }

  bool get _endBeforeStart => _start != null && _end != null && _end!.isBefore(_start!);

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = (isStart ? _start : _end) ?? _start ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end == null || _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
    });
    final hasRowError = _team.any((r) => _rowError(r) != null);
    if (_name.text.trim().isEmpty || hasRowError || _endBeforeStart) return;

    final attendees = _team
        .where((r) => isValidIndianMobile(r.mobile.text.trim()))
        .map(
          (r) => Attendee(
            name: r.name.text.trim().isEmpty ? 'Attendee' : r.name.text.trim(),
            mobile: r.mobile.text.trim(),
          ),
        )
        .toList();

    setState(() => _saving = true);
    try {
      final req = CreateExhibitionRequest(
        name: _name.text.trim(),
        venue: _venue.text.trim(),
        city: _city.text.trim(),
        startDate: _start,
        endDate: _end,
        // New exhibitions always start as Active.
        // No status picker: create and edit always send Active.
        status: ExhibitionStatus.active,
        notes: _notes.text.trim(),
        attendees: attendees,
      );
      final repo = ref.read(exhibitionRepositoryProvider);
      if (_editing) {
        await repo.updateExhibition(widget.initial!.id, req);
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      final created = await repo.createExhibition(req);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = exIsWide(context);
    final nameError = _tried && _name.text.trim().isEmpty ? 'Exhibition name is required' : null;

    return ExTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: exPageBg,
          body: SafeArea(
            top: false,
            bottom: false, // the white footer draws under the home indicator
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: exBorder)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: 'Close',
                              icon: const Icon(Icons.close_rounded, color: exInk, size: 26),
                              onPressed: _saving ? null : () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_editing ? 'Edit exhibition' : 'New exhibition',
                                style: exHeadingMd),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 24 : 16),
                    child: ExMaxWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(
                            title: 'Details',
                            children: [
                              ExField(
                                label: 'Name',
                                required: true,
                                controller: _name,
                                hint: 'e.g. DIDAC India 2026',
                                errorText: nameError,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) {
                                  if (_tried) setState(() {});
                                },
                              ),
                              _pair(
                                wide,
                                ExField(
                                  label: 'Venue',
                                  controller: _venue,
                                  hint: 'e.g. Yashobhoomi (IICC)',
                                  textCapitalization: TextCapitalization.words,
                                ),
                                ExField(
                                  label: 'City',
                                  controller: _city,
                                  hint: 'e.g. New Delhi',
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              _pair(
                                true,
                                _DateField(
                                  label: 'Start date',
                                  value: _start,
                                  onTap: () => _pickDate(true),
                                ),
                                _DateField(
                                  label: 'End date',
                                  value: _end,
                                  onTap: () => _pickDate(false),
                                  error: _tried && _endBeforeStart
                                      ? "End date can't be before the start date"
                                      : null,
                                ),
                              ),
                              ExField(
                                label: 'Notes',
                                controller: _notes,
                                hint: 'e.g. Hall 3, Stall 42',
                                maxLines: 3,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _section(
                            title: 'Attendees',
                            subtitle: 'These people will receive a call on every demo.',
                            children: [
                              if (_team.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: exPageBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'No attendees yet.',
                                    textAlign: TextAlign.center,
                                    style: exBodyMd,
                                  ),
                                ),
                              for (var i = 0; i < _team.length; i++) _teamRow(i, wide),
                              ExSecondaryButton(
                                label: 'Add attendee',
                                icon: Icons.person_add_alt_outlined,
                                color: exBrandBold,
                                onPressed: () => setState(() => _team.add(_TeamRow())),
                              ),
                            ],
                          ),
                          if (_serverError != null) ...[
                            const SizedBox(height: 16),
                            ExInlineNote(message: _serverError!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: exBorder)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SafeArea(
                    top: false,
                    child: ExMaxWidth(
                      child: ExPrimaryButton(
                        label: _editing ? 'Save Changes' : 'Create Exhibition',
                        loadingLabel: _editing ? 'Saving…' : 'Creating…',
                        loading: _saving,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: exBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: exHeadingMd),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: exBodyMd)],
            const SizedBox(height: 16),
            for (final c in children) ...[c, const SizedBox(height: 16)],
          ],
        ),
      );

  Widget _pair(bool wide, Widget a, Widget b) => wide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        )
      : Column(children: [a, const SizedBox(height: 16), b]);

  Widget _teamRow(int i, bool wide) {
    final r = _team[i];
    final err = _rowError(r);
    final name = TextField(
      controller: r.name,
      textCapitalization: TextCapitalization.words,
      style: exBodyTouch,
      decoration: exInputDecoration(hint: 'Name'),
    );
    final mobile = TextField(
      controller: r.mobile,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        const ExAsciiDigitsFormatter(),
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (_) {
        if (_tried) setState(() {});
      },
      style: exBodyTouch,
      decoration: exInputDecoration(hint: 'Enter 10-digit mobile number', prefixText: '+91', errorText: err),
    );
    final remove = SizedBox(
      width: 48,
      height: 52,
      child: IconButton(
        tooltip: 'Remove attendee ${i + 1}',
        icon: const Icon(Icons.delete_outline_rounded, color: exDanger),
        onPressed: () => _removeRow(r),
      ),
    );
    return Dismissible(
      key: ObjectKey(r),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: exDangerBg, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.delete_outline_rounded, color: exDanger),
      ),
      onDismissed: (_) => _removeRow(r),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: name),
                const SizedBox(width: 10),
                Expanded(child: mobile),
                const SizedBox(width: 4),
                remove,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: [name, const SizedBox(height: 8), mobile])),
                const SizedBox(width: 4),
                remove,
              ],
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? error;

  const _DateField({required this.label, required this.value, required this.onTap, this.error});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: exHeadingSm.copyWith(fontSize: 15)),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: exInputDecoration(errorText: error).copyWith(
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: exSubtle),
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          ),
          child: Text(
            value == null ? 'Select date' : exDateRange(value, value),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: exBodyTouch.copyWith(color: value == null ? const Color(0xFF9A9AA3) : exInk),
          ),
        ),
      ),
    ],
  );
}
