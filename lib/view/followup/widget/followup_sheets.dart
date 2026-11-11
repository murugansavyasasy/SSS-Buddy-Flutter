import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/FollowUpModel.dart';
import '../../../viewModel/followup_viewmodel.dart';
import 'followup_common.dart';

const _outcomeChips = [
  'Interested',
  'Call back later',
  'Not reachable',
  'Demo scheduled',
  'PO expected',
  'Payment promised',
  'Not interested',
];

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(child: SingleChildScrollView(child: child)),
      ),
    );

Widget _sheetTitle(String title, String subtitle) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );

/// Quick reschedule; returns once saved or dismissed.
Future<void> showRescheduleSheet(
    BuildContext context, WidgetRef ref, FollowUp f) {
  return _sheet(
    context,
    Builder(builder: (ctx) {
      Future<void> apply(DateTime t) async {
        Navigator.pop(ctx);
        await ref.read(followUpProvider.notifier).reschedule(f, t);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rescheduled to ${formatDue(t)}')),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Reschedule', f.schoolName),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: QuickPickChips(
              selected: null,
              onPicked: apply,
              onCustom: () async {
                final t = await pickFollowUpDateTime(ctx, f.dueAt);
                if (t != null) await apply(t);
              },
            ),
          ),
        ],
      );
    }),
  );
}

/// Mark done with an outcome, and optionally book the next follow-up.
Future<void> showCompleteSheet(
    BuildContext context, WidgetRef ref, FollowUp f) {
  return _sheet(context, _CompleteSheet(parentContext: context, item: f));
}

class _CompleteSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final FollowUp item;

  const _CompleteSheet({required this.parentContext, required this.item});

  @override
  ConsumerState<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends ConsumerState<_CompleteSheet> {
  final _outcome = TextEditingController();
  bool _scheduleNext = true;
  DateTime? _nextAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nextAt = followUpQuickPicks().firstWhere((p) => p.$1 == 'In 3 days').$2;
  }

  @override
  void dispose() {
    _outcome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final outcome = _outcome.text.trim();
    if (outcome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a short outcome')),
      );
      return;
    }
    setState(() => _saving = true);
    final f = widget.item;
    final vm = ref.read(followUpProvider.notifier);
    FollowUp? next;
    if (_scheduleNext && _nextAt != null) {
      next = vm.draft(
        schoolId: f.schoolId,
        schoolName: f.schoolName,
        contactName: f.contactName,
        contactPhone: f.contactPhone,
        type: f.type,
        dueAt: _nextAt!,
        remindBefore: f.remindBefore,
        note: 'Previous: $outcome',
        demoId: f.demoId,
      );
    }
    await vm.complete(f, outcome: outcome, next: next);
    if (!mounted) return;
    Navigator.pop(context);
    final ctx = widget.parentContext;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(next == null
            ? 'Follow-up marked done'
            : 'Done · next follow-up ${formatDue(next.dueAt)}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetTitle('Mark as done', widget.item.schoolName),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outcome',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _outcomeChips)
                    ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _outcome.text = c;
                        _outcome.selection = TextSelection.collapsed(
                            offset: _outcome.text.length);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _outcome,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'What happened?',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _scheduleNext,
                onChanged: (v) => setState(() => _scheduleNext = v),
                activeColor: AppColors.primary,
                title: const Text('Schedule next follow-up',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              if (_scheduleNext)
                QuickPickChips(
                  selected: _nextAt,
                  onPicked: (t) => setState(() => _nextAt = t),
                  onCustom: () async {
                    final t = await pickFollowUpDateTime(
                        context, _nextAt ?? DateTime.now());
                    if (t != null) setState(() => _nextAt = t);
                  },
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doneColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
