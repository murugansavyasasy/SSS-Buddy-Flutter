import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ExhibitionModel.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'widget/exhibition_common.dart';

class _TeamRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController mobile = TextEditingController();

  void dispose() {
    name.dispose();
    mobile.dispose();
  }
}

/// POST /api/mobile/exhibitions. Pops with the created [Exhibition].
class ExhibitionCreateView extends ConsumerStatefulWidget {
  const ExhibitionCreateView({super.key});

  @override
  ConsumerState<ExhibitionCreateView> createState() => _ExhibitionCreateViewState();
}

class _ExhibitionCreateViewState extends ConsumerState<ExhibitionCreateView> {
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  final List<_TeamRow> _team = [_TeamRow()];

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
        .map((r) => Attendee(
              name: r.name.text.trim().isEmpty ? 'Attender' : r.name.text.trim(),
              mobile: r.mobile.text.trim(),
            ))
        .toList();

    setState(() => _saving = true);
    try {
      final created = await ref.read(exhibitionRepositoryProvider).createExhibition(
            CreateExhibitionRequest(
              name: _name.text.trim(),
              venue: _venue.text.trim(),
              city: _city.text.trim(),
              startDate: _start,
              endDate: _end,
              // New exhibitions always start as Active.
              status: ExhibitionStatus.active,
              notes: _notes.text.trim(),
              attendees: attendees,
            ),
          );
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

    return Scaffold(
      backgroundColor: exPageBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: const Text('New exhibition',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
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
                            wide,
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
                        title: 'Attenders',
                        subtitle: 'These people will receive a call on every demo.',
                        children: [
                          if (_team.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: exStrongBorder),
                              ),
                              child: const Text('No attenders yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: exSubtle)),
                            ),
                          for (var i = 0; i < _team.length; i++) _teamRow(i, wide),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _team.add(_TeamRow())),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Add attender'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: exStrongBorder),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_serverError != null) ...[
                        const SizedBox(height: 16),
                        _ErrorNote(message: _serverError!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ExMaxWidth(
                child: ExPrimaryButton(
                  label: 'Create Exhibition',
                  loadingLabel: 'Creating…',
                  loading: _saving,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: exBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: exInk)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13.5, color: exSubtle)),
            ],
            const SizedBox(height: 14),
            for (final c in children) ...[c, const SizedBox(height: 14)],
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
      : Column(children: [a, const SizedBox(height: 14), b]);

  Widget _teamRow(int i, bool wide) {
    final r = _team[i];
    final err = _rowError(r);
    final name = TextField(
      controller: r.name,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 16, color: exInk),
      decoration: exInputDecoration(hint: 'Name'),
    );
    final mobile = TextField(
      controller: r.mobile,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (_) {
        if (_tried) setState(() {});
      },
      style: const TextStyle(fontSize: 16, color: exInk),
      decoration: exInputDecoration(hint: '10-digit mobile', prefixText: '+91  ', errorText: err),
    );
    final remove = SizedBox(
      width: 48,
      height: 52,
      child: IconButton(
        tooltip: 'Remove attender ${i + 1}',
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
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(10),
        ),
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
                Expanded(
                  child: Column(
                    children: [name, const SizedBox(height: 8), mobile],
                  ),
                ),
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
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: exInputDecoration(errorText: error).copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(
                value == null ? 'Select date' : exDateRange(value, value),
                style: TextStyle(
                  fontSize: 16,
                  color: value == null ? Colors.grey.shade400 : exInk,
                ),
              ),
            ),
          ),
        ],
      );
}

class _ErrorNote extends StatelessWidget {
  final String message;
  const _ErrorNote({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: exDanger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: exDanger, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
