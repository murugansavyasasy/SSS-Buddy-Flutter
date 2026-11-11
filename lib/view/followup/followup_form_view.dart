import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/FollowUpModel.dart';
import '../../auth/model/SchoolNameModel.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/followup_viewmodel.dart';
import '../../viewModel/schollname_dd_viewmodel.dart';
import 'widget/followup_common.dart';
import 'widget/followup_sheets.dart';

class FollowUpFormView extends ConsumerStatefulWidget {
  final FollowUpFormArgs args;

  const FollowUpFormView({super.key, this.args = const FollowUpFormArgs()});

  @override
  ConsumerState<FollowUpFormView> createState() => _FollowUpFormViewState();
}

class _FollowUpFormViewState extends ConsumerState<FollowUpFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _school;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  late String _schoolId;
  late FollowUpType _type;
  DateTime? _dueAt;
  late int _remindBefore;
  bool _saving = false;

  FollowUp? get _existing => widget.args.existing;

  bool get _isEdit => _existing != null;

  bool get _readOnly => _existing != null && !_existing!.isPending;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final a = widget.args;
    _school = TextEditingController(text: e?.schoolName ?? a.schoolName);
    _contact = TextEditingController(text: e?.contactName ?? '');
    _phone = TextEditingController(text: e?.contactPhone ?? a.contactPhone);
    _note = TextEditingController(text: e?.note ?? '');
    _schoolId = e?.schoolId ?? a.schoolId;
    _type = e?.type ?? a.type ?? FollowUpType.call;
    _dueAt = e?.dueAt ??
        followUpQuickPicks().firstWhere((p) => p.$1 == 'Tomorrow 10 AM').$2;
    _remindBefore = e?.remindBefore ?? 15;
  }

  @override
  void dispose() {
    _school.dispose();
    _contact.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueAt == null) return;
    if (_dueAt!.isBefore(DateTime.now()) &&
        (!_isEdit || _dueAt != _existing!.dueAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a time in the future')),
      );
      return;
    }
    setState(() => _saving = true);
    final vm = ref.read(followUpProvider.notifier);
    final e = _existing;
    final f = e == null
        ? vm.draft(
            schoolId: _schoolId,
            schoolName: _school.text.trim(),
            contactName: _contact.text.trim(),
            contactPhone: _phone.text.trim(),
            type: _type,
            dueAt: _dueAt!,
            remindBefore: _remindBefore,
            note: _note.text.trim(),
            demoId: widget.args.demoId,
          )
        : e.copyWith(
            schoolId: _schoolId,
            schoolName: _school.text.trim(),
            contactName: _contact.text.trim(),
            contactPhone: _phone.text.trim(),
            type: _type,
            dueAt: _dueAt,
            remindBefore: _remindBefore,
            note: _note.text.trim(),
          );
    try {
      await vm.save(f);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Follow-up updated'
            : 'Follow-up set for ${formatDue(_dueAt!)}'),
      ));
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $err')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete follow-up?'),
        content: Text(_existing!.schoolName),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(followUpProvider.notifier).delete(_existing!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: _readOnly
                  ? 'Follow-up'
                  : _isEdit
                      ? 'Edit Follow-up'
                      : 'New Follow-up',
              trailing: _isEdit
                  ? GestureDetector(
                      onTap: _delete,
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 20),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                    children: [
                      if (_readOnly) _doneBanner(),
                      _label('School'),
                      _schoolField(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Contact person'),
                                _field(_contact, 'Principal / Admin',
                                    icon: Icons.person_outline_rounded),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Phone'),
                                _field(_phone, 'Mobile number',
                                    icon: Icons.phone_outlined,
                                    keyboard: TextInputType.phone),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _label('Type'),
                      _typeChips(),
                      const SizedBox(height: 18),
                      _label('When'),
                      if (_readOnly)
                        Text(formatDue(_dueAt!))
                      else
                        QuickPickChips(
                          selected: _dueAt,
                          onPicked: (t) => setState(() => _dueAt = t),
                          onCustom: () async {
                            final t = await pickFollowUpDateTime(
                                context, _dueAt ?? DateTime.now());
                            if (t != null) setState(() => _dueAt = t);
                          },
                        ),
                      if (!_readOnly && _dueAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Due ${formatDue(_dueAt!)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: upcomingColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _label('Remind me'),
                      _reminderChips(),
                      const SizedBox(height: 18),
                      _label('Note'),
                      _field(_note, 'What to discuss, objections, next step…',
                          lines: 3),
                      const SizedBox(height: 26),
                      if (!_readOnly) _saveButton(),
                      if (_isEdit && _existing!.isPending) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await showCompleteSheet(context, ref, _existing!);
                              final still = ref
                                  .read(followUpProvider)
                                  .value
                                  ?.where((x) => x.id == _existing!.id)
                                  .firstOrNull;
                              if (mounted && (still == null || !still.isPending)) {
                                Navigator.pop(context);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: doneColor,
                              side: const BorderSide(color: doneColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Mark as done'),
                          ),
                        ),
                      ],
                      if (_readOnly) ...[
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(followUpProvider.notifier)
                                  .reopen(_existing!);
                              if (mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Reopen'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneBanner() {
    final e = _existing!;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: doneColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: doneColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.completedAt == null
                      ? 'Completed'
                      : 'Completed ${formatDue(e.completedAt!)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: doneColor),
                ),
                if (e.outcome.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(e.outcome),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      );

  InputDecoration _decoration(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _field(TextEditingController c, String hint,
      {IconData? icon, TextInputType? keyboard, int lines = 1}) {
    return TextFormField(
      controller: c,
      readOnly: _readOnly,
      keyboardType: keyboard,
      minLines: lines,
      maxLines: lines,
      textCapitalization: keyboard == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: _decoration(hint, icon: icon),
    );
  }

  Widget _schoolField() {
    final schools = ref.watch(schoolnameProvider).value ?? const [];
    return Autocomplete<Schoolnamemodel>(
      initialValue: _school.value,
      displayStringForOption: (s) => s.CustomerName,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.length < 2) return const Iterable<Schoolnamemodel>.empty();
        return schools
            .where((s) => s.CustomerName.toLowerCase().contains(q))
            .take(20);
      },
      onSelected: (s) {
        _school.text = s.CustomerName;
        _schoolId = s.CustomerID;
      },
      fieldViewBuilder: (context, controller, focus, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focus,
          readOnly: _readOnly,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration('Search or type school name',
              icon: Icons.account_balance_outlined),
          onChanged: (v) {
            // Typed (not picked from the list): keep text, drop stale id.
            _school.text = v;
            _schoolId = '';
          },
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'School name is required' : null,
        );
      },
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in FollowUpType.values)
          ChoiceChip(
            avatar: Icon(t.icon,
                size: 16, color: _type == t ? Colors.white : t.color),
            label: Text(t.label),
            selected: _type == t,
            showCheckmark: false,
            selectedColor: t.color,
            labelStyle: TextStyle(
              fontSize: 12.5,
              color: _type == t ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            onSelected: _readOnly ? null : (_) => setState(() => _type = t),
          ),
      ],
    );
  }

  Widget _reminderChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in followUpReminderOptions.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: _remindBefore == e.key,
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              fontSize: 12.5,
              color: _remindBefore == e.key ? AppColors.primary : Colors.black87,
              fontWeight:
                  _remindBefore == e.key ? FontWeight.w600 : FontWeight.normal,
            ),
            onSelected:
                _readOnly ? null : (_) => setState(() => _remindBefore = e.key),
          ),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                _isEdit ? 'Update' : 'Save Follow-up',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
      ),
    );
  }
}
