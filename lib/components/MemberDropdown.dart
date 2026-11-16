import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/ReportingMembersModel.dart';

/// Member picker: looks like a dropdown, opens a searchable list.
class MemberDropdown extends StatelessWidget {
  final List<Reportingmembersmodel> members;
  final Reportingmembersmodel? selected;
  final ValueChanged<Reportingmembersmodel?> onChanged;

  const MemberDropdown({
    required this.members,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Reportingmembersmodel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberSearchSheet(members: members, selected: selected),
    );
    if (picked != null && picked != selected) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              if (selected != null) ...[
                _MemberAvatar(name: selected!.membername),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  selected?.membername ?? 'Select Member',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected == null ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String name;
  const _MemberAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MemberSearchSheet extends StatefulWidget {
  final List<Reportingmembersmodel> members;
  final Reportingmembersmodel? selected;

  const _MemberSearchSheet({required this.members, required this.selected});

  @override
  State<_MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<_MemberSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? widget.members
        : widget.members
            .where((m) => m.membername.toLowerCase().contains(q))
            .toList();

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Member',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search member name',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No member found',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final m = results[i];
                        final isSelected =
                            widget.selected?.idmember == m.idmember;
                        return ListTile(
                          onTap: () => Navigator.pop(context, m),
                          leading: _MemberAvatar(name: m.membername),
                          title: Text(
                            m.membername,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_rounded, color: AppColors.primary)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
