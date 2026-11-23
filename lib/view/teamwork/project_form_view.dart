import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/glass_card.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import 'widget/teamwork_common.dart';

/// Admin creates or edits a project: name, colour, modules and milestones.
/// Route argument: the project id to edit (null = new). Pops with true.
class ProjectFormView extends ConsumerStatefulWidget {
  final String? projectId;
  const ProjectFormView({super.key, this.projectId});

  @override
  ConsumerState<ProjectFormView> createState() => _ProjectFormViewState();
}

class _MilestoneDraft {
  final String id;
  final TextEditingController title;
  DateTime? due;
  final DateTime? completedAt;
  _MilestoneDraft({this.id = '', String text = '', this.due, this.completedAt})
      : title = TextEditingController(text: text);
}

class _ModuleDraft {
  final String id;
  final TextEditingController name;
  _ModuleDraft({this.id = '', String text = ''}) : name = TextEditingController(text: text);
}

class _ProjectFormViewState extends ConsumerState<ProjectFormView> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  Color _color = projectColors.first;
  final List<_ModuleDraft> _modules = [];
  final List<_MilestoneDraft> _milestones = [];
  Project? _original;
  bool _loaded = false;
  bool _tried = false;
  bool _saving = false;

  bool get _editing => widget.projectId != null;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    for (final m in _modules) {
      m.name.dispose();
    }
    for (final m in _milestones) {
      m.title.dispose();
    }
    super.dispose();
  }

  void _load(List<Project> projects) {
    if (_loaded) return;
    _loaded = true;
    final p = projects.where((x) => x.id == widget.projectId).firstOrNull;
    if (p == null) {
      _modules.add(_ModuleDraft());
      return;
    }
    _original = p;
    _name.text = p.name;
    _desc.text = p.description;
    _color = p.color;
    _modules.addAll(p.modules.map((m) => _ModuleDraft(id: m.id, text: m.name)));
    _milestones.addAll(
        p.milestones.map((m) => _MilestoneDraft(id: m.id, text: m.title, due: m.dueDate, completedAt: m.completedAt)));
    if (_modules.isEmpty) _modules.add(_ModuleDraft());
  }

  List<ProjectModule> get _cleanModules => [
        for (final m in _modules)
          if (m.name.text.trim().isNotEmpty) ProjectModule(id: m.id, name: m.name.text.trim()),
      ];

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty || _cleanModules.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    final p = Project(
      id: _original?.id ?? '',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      color: _color,
      modules: _cleanModules,
      milestones: [
        for (final m in _milestones)
          if (m.title.text.trim().isNotEmpty)
            Milestone(id: m.id, title: m.title.text.trim(), dueDate: m.due, completedAt: m.completedAt),
      ],
      createdAt: _original?.createdAt,
    );
    try {
      await ref.read(teamWorkActionsProvider).saveProject(p);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickDue(_MilestoneDraft m) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: m.due ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1095)),
    );
    if (d != null) setState(() => m.due = d);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectsProvider);
    return TeamPage(
      title: _editing ? 'Edit Project' : 'New Project',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            TeamStateView.error(e, title: "Couldn't load project", onRetry: () => ref.invalidate(projectsProvider)),
        data: (projects) {
          _load(projects);
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        TeamFormField(
                          label: 'Project name',
                          error: _tried && _name.text.trim().isEmpty ? 'Project name is required' : null,
                          child: TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                            decoration: teamInput('e.g. SSS Score App', icon: Icons.folder_rounded),
                          ),
                        ),
                        TeamFormField(
                          label: 'Description (optional)',
                          child: TextField(
                            controller: _desc,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: teamInput('What is this project about?'),
                          ),
                        ),
                        TeamFormField(
                          label: 'Colour',
                          child: Wrap(
                            spacing: 10,
                            children: [
                              for (final c in projectColors)
                                GestureDetector(
                                  onTap: () => setState(() => _color = c),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: c.toARGB32() == _color.toARGB32() ? teamInk : Colors.transparent, width: 3),
                                    ),
                                    child: c.toARGB32() == _color.toARGB32()
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _listHeader(
                          'Modules',
                          'Parts of the project tasks belong to (e.g. Login, Reports, API).',
                          onAdd: () => setState(() => _modules.add(_ModuleDraft())),
                        ),
                        if (_tried && _cleanModules.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Add at least one module',
                                style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                          ),
                        for (final (i, m) in _modules.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: m.name,
                                    textCapitalization: TextCapitalization.words,
                                    onChanged: (_) => _tried ? setState(() {}) : null,
                                    decoration: teamInput('Module ${i + 1}', icon: Icons.widgets_rounded),
                                  ),
                                ),
                                if (_modules.length > 1)
                                  IconButton(
                                    onPressed: () => setState(() => _modules.removeAt(i).name.dispose()),
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: teamSubtle),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        _listHeader(
                          'Milestones',
                          'Checkpoints with a due date. A milestone completes when all its tasks are done.',
                          onAdd: () => setState(() => _milestones.add(_MilestoneDraft())),
                        ),
                        if (_milestones.isEmpty)
                          SoftCard(
                            radius: 14,
                            padding: const EdgeInsets.all(14),
                            child: const Text('No milestones yet. Add one to track bigger goals.', style: teamBodyStyle),
                          ),
                        for (final (i, m) in _milestones.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftCard(
                              radius: 16,
                              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: m.title,
                                          textCapitalization: TextCapitalization.sentences,
                                          decoration: teamInput('Milestone ${i + 1}', icon: Icons.outlined_flag_rounded),
                                        ),
                                        const SizedBox(height: 8),
                                        TeamPickerBox(
                                          icon: Icons.event_rounded,
                                          text: m.due == null ? 'Due date' : 'Due ${teamDate(m.due)}',
                                          placeholder: m.due == null,
                                          onTap: () => _pickDue(m),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _milestones.removeAt(i).title.dispose()),
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: teamSubtle),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: teamBorder)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _saving ? 'Saving…' : (_editing ? 'Update Project' : 'Create Project'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _listHeader(String title, String sub, {required VoidCallback onAdd}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: teamInk)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12, color: teamSubtle)),
                ],
              ),
            ),
            TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add')),
          ],
        ),
      );
}
