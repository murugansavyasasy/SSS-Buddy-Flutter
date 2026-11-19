import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'widget/exhibition_common.dart';

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

  /// Added attendees, shown as chips; the two fields below add one more.
  late final List<Attendee> _attendees = [...?widget.initial?.attendees];
  final _attName = TextEditingController();
  final _attMobile = TextEditingController();
  String? _attError;

  bool get _editing => widget.initial != null;

  /// Edit only: the full exhibition (team, notes, …) is fetched first so
  /// the form shows everything the API has, not just the list row.
  bool _loading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    if (_editing) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    final base = widget.initial!;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Straight from the repository: invalidating exhibitionDetailProvider
      // here would rebuild the detail screen underneath mid-build and throw.
      final fresh = await ref.read(exhibitionRepositoryProvider).fetchExhibition(base.id);
      if (!mounted) return;
      _fill(fresh.mergedWith(base));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  void _fill(Exhibition ex) {
    _name.text = ex.name;
    _venue.text = ex.venue;
    _city.text = ex.city;
    _notes.text = ex.notes;
    _start = ex.startDate;
    _end = ex.endDate;
    _status = ex.status;
    _attendees
      ..clear()
      ..addAll(ex.attendees);
  }

  /// Kept as-is on edit (there is no status picker); new ones start Active.
  late ExhibitionStatus _status = widget.initial?.status ?? ExhibitionStatus.active;

  bool _tried = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _notes.dispose();
    _attName.dispose();
    _attMobile.dispose();
    super.dispose();
  }

  /// Adds the typed name + number as a chip. Returns false (and shows the
  /// reason) when the number is missing, invalid or already added.
  bool _addAttendee() {
    final m = _attMobile.text.trim();
    final n = _attName.text.trim();
    String? err;
    if (m.isEmpty) {
      err = 'Enter a mobile number';
    } else if (!isValidIndianMobile(m)) {
      err = 'Enter a 10-digit mobile number';
    } else if (_attendees.any((a) => a.mobile == m)) {
      err = 'This number is already added';
    }
    if (err != null) {
      setState(() => _attError = err);
      return false;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _attendees.add(Attendee(name: n.isEmpty ? 'Attendee' : n, mobile: m));
      _attName.clear();
      _attMobile.clear();
      _attError = null;
    });
    return true;
  }

  /// Everything except City and Notes is mandatory.
  bool get _hasErrors =>
      _name.text.trim().isEmpty ||
      _venue.text.trim().isEmpty ||
      _start == null ||
      _end == null ||
      _endBeforeStart ||
      _attendees.isEmpty;

  bool get _endBeforeStart => _start != null && _end != null && _end!.isBefore(_start!);

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = (isStart ? _start : _end) ?? _start ?? now;
    // Widen the range so an older / far-off saved date can still open.
    var first = DateTime(now.year - 2);
    var last = DateTime(now.year + 3);
    if (initial.isBefore(first)) first = DateTime(initial.year);
    if (initial.isAfter(last)) last = DateTime(initial.year, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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
    // A number still in the fields (Add not tapped) is added now; an
    // invalid one blocks saving.
    final pending = _attMobile.text.trim().isNotEmpty || _attName.text.trim().isNotEmpty;
    final attendeeOk = !pending || _addAttendee();
    if (!attendeeOk || _hasErrors) return;

    final attendees = List<Attendee>.of(_attendees);

    setState(() => _saving = true);
    try {
      final req = CreateExhibitionRequest(
        name: _name.text.trim(),
        venue: _venue.text.trim(),
        city: _city.text.trim(),
        startDate: _start,
        endDate: _end,
        // New exhibitions start as Active; an edit keeps the current status.
        status: _status,
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
    final venueError = _tried && _venue.text.trim().isEmpty ? 'Venue is required' : null;
    final startError = _tried && _start == null ? 'Start date is required' : null;
    final endError = !_tried
        ? null
        : _end == null
        ? 'End date is required'
        : _endBeforeStart
        ? "End date can't be before the start date"
        : null;
    final attendeesError = _tried && _attendees.isEmpty ? 'Add at least one attendee' : null;

    return ExTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: exHeaderOverlay,
        child: Scaffold(
          backgroundColor: exHeaderBase,
          body: SafeArea(
            top: false,
            bottom: false, // the white footer draws under the home indicator
            child: Column(
              children: [
                ExGradientHeader(
                  child: Row(
                    children: [
                      ExHeaderIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: _saving ? null : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _editing ? 'Edit exhibition' : 'New exhibition',
                          style: exHeadingMd.copyWith(fontSize: 19),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ExCurvedBody(
                    child: Column(
                      children: [
                        if (_loading)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator(color: exBrandBold)),
                          )
                        else if (_loadError != null)
                          Expanded(
                            child: Center(
                              child: ExStateView.error(
                                _loadError!,
                                title: "Couldn't load exhibition",
                                onRetry: _loadForEdit,
                              ),
                            ),
                          )
                        else ...[
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(wide ? 24 : 16),
                              child: ExMaxWidth(
                                maxWidth: exFormMaxWidth,
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
                                          hint: 'Enter exhibition name',
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
                                            required: true,
                                            controller: _venue,
                                            errorText: venueError,
                                            onChanged: (_) {
                                              if (_tried) setState(() {});
                                            },
                                            hint: 'Enter venue',
                                            textCapitalization: TextCapitalization.words,
                                          ),
                                          ExField(
                                            label: 'City',
                                            controller: _city,
                                            hint: 'Enter city',
                                            textCapitalization: TextCapitalization.words,
                                          ),
                                        ),
                                        _pair(
                                          true,
                                          _DateField(
                                            label: 'Start date',
                                            required: true,
                                            value: _start,
                                            error: startError,
                                            onTap: () => _pickDate(true),
                                          ),
                                          _DateField(
                                            label: 'End date',
                                            value: _end,
                                            required: true,
                                            onTap: () => _pickDate(false),
                                            error: endError,
                                          ),
                                        ),
                                        ExField(
                                          label: 'Notes',
                                          controller: _notes,
                                          hint: 'Enter notes',
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _section(
                                      title: 'Attendees',
                                      required: true,
                                      subtitle: 'These people will receive a call on every demo.',
                                      children: [
                                        _attendeeInput(wide),
                                        _attendeeChips(),
                                        if (attendeesError != null)
                                          Text(
                                            attendeesError,
                                            style: exBodySm.copyWith(color: exDanger),
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
                                maxWidth: exFormMaxWidth,
                                child: ExPrimaryButton(
                                  label: _editing ? 'Update Exhibition' : 'Create Exhibition',
                                  loadingLabel: _editing ? 'Updating…' : 'Creating…',
                                  loading: _saving,
                                  onPressed: _submit,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _section({
    required String title,
    String? subtitle,
    bool required = false,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: exBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: exDanger),
                ),
            ],
          ),
          style: exHeadingMd,
        ),
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

  /// Name + number fields with an Add button.
  Widget _attendeeInput(bool wide) {
    final name = TextField(
      controller: _attName,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: exBodyTouch,
      decoration: exInputDecoration(hint: 'Enter name'),
    );
    final mobile = TextField(
      controller: _attMobile,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _addAttendee(),
      inputFormatters: [
        const ExAsciiDigitsFormatter(),
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (_) {
        if (_attError != null) setState(() => _attError = null);
      },
      style: exBodyTouch,
      decoration: exInputDecoration(
        hint: 'Enter 10-digit mobile number',
        prefixText: '+91',
        errorText: _attError,
      ),
    );
    final add = SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _saving ? null : _addAttendee,
        style: FilledButton.styleFrom(
          backgroundColor: exBrandBold,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add'),
      ),
    );
    // Add sits below the number field (full width on phones).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: name),
              const SizedBox(width: 10),
              Expanded(child: mobile),
            ],
          )
        else ...[
          name,
          const SizedBox(height: 8),
          mobile,
        ],
        const SizedBox(height: 10),
        if (wide) Align(alignment: Alignment.centerRight, child: add) else add,
      ],
    );
  }

  /// Added attendees as removable chips.
  Widget _attendeeChips() {
    if (_attendees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: exPageBg, borderRadius: BorderRadius.circular(8)),
        child: const Text('No attendees added yet.', textAlign: TextAlign.center, style: exBodyMd),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Added (${_attendees.length})', style: exBodySm),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in _attendees)
              ExPersonChip(
                key: ValueKey(a.mobile),
                name: a.name,
                number: formatIndianMobile(a.mobile),
                onRemove: () {
                  if (!_saving) setState(() => _attendees.remove(a));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? error;
  final bool required;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: exDanger),
              ),
          ],
        ),
        style: exHeadingSm.copyWith(fontSize: 15),
      ),
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
