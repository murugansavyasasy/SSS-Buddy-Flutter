import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/model/FinancialYearModel.dart';
import '../../auth/model/PaymentSubmissionModel.dart';
import '../../core/network/DioClient.dart';
import '../../viewModel/payment_submission_viewmodel.dart';
import 'widget/payment_common.dart';

/// Submit payment in four steps: School → Proforma → Proof (AI reads it) →
/// Check details. Pops with the new [PaymentSubmission].
class PaymentSubmitView extends ConsumerStatefulWidget {
  const PaymentSubmitView({super.key});

  @override
  ConsumerState<PaymentSubmitView> createState() => _PaymentSubmitViewState();
}

/// Proof files: image or PDF, 10 MB max, up to 10 per submission.
const _maxProofBytes = 10 * 1024 * 1024;
const _maxProofs = 10;
const _proofExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'pdf'];

/// Used when GET /payment-modes fails.
final _fallbackModes = [
  for (final v in ['upi', 'neft', 'rtgs', 'imps', 'cheque', 'cash', 'bank_transfer', 'other'])
    Paymentmodemodel(value: v, label: paymentModeLabel(v)),
];

/// A picked proof file and where its upload / AI read stands.
class _Proof {
  final String path;
  final String name;
  double progress = 0;
  bool busy = true;

  /// True while the server reads it (after the upload finished).
  bool reading = false;
  PsExtraction? read;

  /// Stored URL (from the AI read, or the S3 fallback).
  String url = '';

  /// Upload failed completely; the user can retry or remove it.
  String? error;

  _Proof(this.path, this.name);

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

class _PaymentSubmitViewState extends ConsumerState<PaymentSubmitView> {
  static const _stepNames = ['School', 'Proforma', 'Proof', 'Details'];
  int _step = 0;
  bool _forward = true;

  // Step 1 · School
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// The search sent to the API; changes only when Search is tapped.
  String _query = '';
  PsCustomer? _customer;

  // Step 2 · Proforma
  PsProforma? _proforma;

  // Step 3 · Proof
  final List<_Proof> _proofs = [];

  // Step 4 · Details
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _bank = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  String? _mode;

  /// AI read already copied into the form (never copied twice, never over
  /// what the user typed).
  int? _prefilledFrom;
  bool _tried = false;
  bool _submitting = false;
  String? _serverError;
  String? _referenceError;

  @override
  void dispose() {
    _searchFocus.dispose();
    for (final c in [_search, _amount, _reference, _bank, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  // MARK: Navigation

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
    });
    if (step == 3) _prefill();
  }

  void _back() {
    if (_submitting) return;
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      _go(_step - 1);
    }
  }

  bool get _uploading => _proofs.any((p) => p.busy);
  List<_Proof> get _stored => _proofs.where((p) => p.url.isNotEmpty).toList();

  /// The AI read to use: the first one with a reference, else the first ok one.
  PsExtraction? get _ai {
    final ok = [for (final p in _proofs) if (p.read?.isOk == true) p.read!];
    for (final r in ok) {
      if (r.txnRef.isNotEmpty) return r;
    }
    return ok.isEmpty ? null : ok.first;
  }

  // MARK: Step 1 · School

  /// Calls the API only when the user taps Search (button or keyboard).
  void _runSearch() {
    _searchFocus.unfocus();
    setState(() => _query = _search.text.trim());
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  void _pickSchool(PsCustomer c) {
    HapticFeedback.selectionClick();
    if (_customer?.id != c.id) _proforma = null;
    _customer = c;
    _go(1);
  }

  // MARK: Step 3 · Proof

  Future<void> _takePhoto() async {
    if (_proofs.length >= _maxProofs) return _toast('Up to $_maxProofs proofs per submission');
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2400);
      if (x == null) return;
      await _addFiles([(x.path, x.name)]);
    } catch (e) {
      _toast("Couldn't open the camera");
    }
  }

  Future<void> _chooseFile() async {
    if (_proofs.length >= _maxProofs) return _toast('Up to $_maxProofs proofs per submission');
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _proofExtensions);
      final files = [
        for (final f in picked)
          if (f.path != null) (f.path!, f.name),
      ];
      await _addFiles(files);
    } catch (e) {
      _toast("Couldn't open the file");
    }
  }

  Future<void> _addFiles(List<(String, String)> files) async {
    final room = _maxProofs - _proofs.length;
    if (files.length > room) _toast('Only $room more proof${room == 1 ? '' : 's'} can be added');
    for (final (path, name) in files.take(room)) {
      final ext = name.split('.').last.toLowerCase();
      if (!_proofExtensions.contains(ext)) {
        _toast('$name is not an image or PDF');
        continue;
      }
      if (await File(path).length() > _maxProofBytes) {
        _toast('$name is over 10 MB');
        continue;
      }
      final p = _Proof(path, name);
      setState(() => _proofs.add(p));
      _upload(p);
    }
  }

  /// Uploads and reads one proof. If the AI read is down the file still
  /// goes to S3, so the user can type the details and submit.
  Future<void> _upload(_Proof p) async {
    final repo = ref.read(paymentSubmissionRepositoryProvider);
    setState(() {
      p
        ..busy = true
        ..error = null
        ..progress = 0
        ..reading = false;
    });
    try {
      final read = await repo.extractProof(p.path, onProgress: (v) {
        if (!mounted) return;
        setState(() {
          p.progress = v;
          if (v >= 1) p.reading = true;
        });
      });
      if (!mounted) return;
      setState(() {
        p.read = read;
        p.url = read.proofUrl;
      });
      if (p.url.isEmpty && !read.notAProof) await _fallbackUpload(p);
    } catch (e) {
      // 503 / offline AI: store the file without a read.
      if (!mounted) return;
      setState(() => p.read = PsExtraction(status: 'failed', error: e.toString()));
      await _fallbackUpload(p);
    }
    if (mounted) setState(() => p.busy = false);
  }

  Future<void> _fallbackUpload(_Proof p) async {
    try {
      setState(() => p.reading = false);
      final url = await ref.read(paymentSubmissionRepositoryProvider).uploadProof(p.path, onProgress: (v) {
        if (mounted) setState(() => p.progress = v);
      });
      if (mounted) setState(() => p.url = url);
    } catch (e) {
      if (mounted) setState(() => p.error = e.toString());
    }
  }

  void _removeProof(_Proof p) => setState(() => _proofs.remove(p));

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  // MARK: Step 4 · Details

  double get _claimable => _proforma?.claimable ?? 0;
  double get _amountValue => parseAmount(_amount.text);

  void _prefill() {
    final ai = _ai;
    if (ai == null || _prefilledFrom == ai.id) return;
    _prefilledFrom = ai.id;
    if (_amount.text.trim().isEmpty && ai.amount > 0 && ai.amount <= _claimable) {
      _amount.text = _plainAmount(ai.amount);
    }
    if (_date == null && ai.txnDate != null && !_isFuture(ai.txnDate!)) _date = ai.txnDate;
    if (_mode == null && ai.formMode.isNotEmpty) _mode = ai.formMode.toLowerCase();
    if (_reference.text.trim().isEmpty && ai.txnRef.isNotEmpty) _reference.text = ai.txnRef;
    if (_bank.text.trim().isEmpty && ai.payerBank.isNotEmpty) _bank.text = ai.payerBank;
    setState(() {});
  }

  static String _plainAmount(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static bool _isFuture(DateTime d) {
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day).isAfter(DateTime(now.year, now.month, now.day));
  }

  String? get _amountError {
    final v = _amountValue;
    if (_amount.text.trim().isEmpty || v <= 0) return 'Enter the amount received';
    if (v > _claimable + 0.001) return 'Only ${formatRupees(_claimable)} is open on this proforma';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(now.year - 2),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
      _referenceError = null;
    });
    if (_amountError != null || _date == null || _stored.isEmpty || _uploading) return;
    final c = _customer!, pf = _proforma!;
    final ai = _ai;
    setState(() => _submitting = true);
    try {
      final (created, message) = await ref.read(paymentSubmissionRepositoryProvider).submit(
            SubmitPaymentRequest(
              customerId: c.id,
              invoiceId: pf.id,
              amount: _amountValue,
              paymentDate: _date!,
              paymentMethod: _mode ?? '',
              referenceNumber: _reference.text.trim(),
              payerBank: _bank.text.trim(),
              notes: _notes.text.trim(),
              proofUrls: [for (final p in _stored) p.url],
              extractionId: ai != null && ai.id > 0 ? ai.id : null,
            ),
          );
      if (!mounted) return;
      _toast(message.isEmpty ? 'Payment submitted' : message);
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = e.toString();
        // 409: this reference was already submitted or receipted.
        if (e is ApiException && e.statusCode == 409) _referenceError = e.message;
      });
    }
  }

  // MARK: Build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PsTheme(
        child: Scaffold(
          backgroundColor: psPageBg,
          body: Column(
            children: [
              PsHeader(
                title: 'Submit payment',
                subtitle: 'Step ${_step + 1} of 4 · ${_stepNames[_step]}',
                progress: (_step + 1) / 4,
                onBack: _back,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, a) {
                    final incoming = child.key == ValueKey(_step);
                    final dx = (incoming == _forward) ? 0.12 : -0.12;
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _schoolStep(),
                      1 => _proformaStep(),
                      2 => _proofStep(),
                      _ => _detailsStep(),
                    },
                  ),
                ),
              ),
              ?_bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _bottomBar() => switch (_step) {
        0 => null,
        1 => _proforma == null
            ? null
            : PsBottomBar(
                child: PsPrimaryButton(label: 'Continue', onPressed: () => _go(2)),
              ),
        2 => PsBottomBar(
            child: PsPrimaryButton(
              label: _uploading ? 'Reading the proof…' : 'Continue',
              onPressed: _stored.isEmpty || _uploading ? null : () => _go(3),
            ),
          ),
        _ => PsBottomBar(
            child: PsPrimaryButton(
              label: 'Submit payment',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _uploading ? null : _submit,
            ),
          ),
      };

  Widget _question(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontFamily: psFont, fontSize: 16, fontWeight: FontWeight.w700, color: psInk)),
      );

  // 1 · School
  Widget _schoolStep() {
    final async = ref.watch(psCustomersProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _question('Which school paid?'),
              PsSearchBar(
                controller: _search,
                focusNode: _searchFocus,
                hint: 'School name or dashboard id',
                onChanged: () => setState(() {}),
                onSearch: _runSearch,
                onClear: _clearSearch,
              ),
              const SizedBox(height: 8),
              const Text('Only schools in your team with a pending proforma are listed.',
                  style: TextStyle(fontFamily: psFont, fontSize: 12, color: psMuted)),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => PsStateView.error(e, onRetry: () => ref.invalidate(psCustomersProvider(_query))),
            data: (list) {
              if (list.isEmpty) {
                return PsStateView(
                  icon: Icons.school_outlined,
                  title: _query.isEmpty ? 'No pending proforma' : 'No school found',
                  message: _query.isEmpty
                      ? 'No school in your team has a pending proforma. Raise the PO or ask accounts.'
                      : 'No school matches “$_query” with a pending proforma.',
                );
              }
              return ListView.separated(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length + (list.length >= 50 ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == list.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Showing the first 50 — type more to narrow it down.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: psFont, fontSize: 12.5, color: psMuted)),
                    );
                  }
                  final c = list[i];
                  return PsAppear(
                    key: ValueKey('c-$_query-${c.id}'),
                    index: i,
                    child: _SchoolRow(customer: c, selected: _customer?.id == c.id, onTap: () => _pickSchool(c)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 2 · Proforma
  Widget _proformaStep() {
    final c = _customer!;
    final async = ref.watch(psProformasProvider(c.id));
    // One proforma → pre-selected.
    final list = async.value;
    if (_proforma == null && list != null && list.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _proforma == null) setState(() => _proforma = list.first);
      });
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SelectedSchool(customer: c, onChange: () => _go(0)),
        const SizedBox(height: 18),
        _question('Which proforma is this payment for?'),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => PsStateView.error(e, onRetry: () => ref.invalidate(psProformasProvider(c.id))),
          data: (list) => list.isEmpty
              ? const PsStateView(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Nothing open to submit',
                  message: 'Everything open on this school already has a submission awaiting the bank.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PsAppear(
                          index: i,
                          child: _ProformaCard(
                            proforma: list[i],
                            selected: _proforma?.id == list[i].id,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _proforma = list[i]);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // 3 · Proof
  Widget _proofStep() {
    final ai = _ai;
    final warnings = {
      for (final p in _proofs)
        if (p.read?.isOk == true) ...p.read!.warnings,
    }.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _question('Upload the payment proof'),
        Text.rich(
          const TextSpan(children: [
            TextSpan(text: 'UPI screenshot, NEFT advice, cheque photo or deposit slip. For UPI, include the screen that shows the '),
            TextSpan(text: 'UPI Ref No.', style: TextStyle(fontWeight: FontWeight.w700, color: psInk)),
          ]),
          style: const TextStyle(fontFamily: psFont, fontSize: 13.5, height: 1.45, color: psSubtle),
        ),
        const SizedBox(height: 14),
        if (_proofs.isEmpty)
          Row(
            children: [
              Expanded(child: _PickButton(icon: Icons.photo_camera_rounded, label: 'Take photo', onTap: _takePhoto)),
              const SizedBox(width: 10),
              Expanded(child: _PickButton(icon: Icons.upload_file_rounded, label: 'Choose file', onTap: _chooseFile)),
            ],
          )
        else ...[
          for (final p in _proofs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PsAppear(
                key: ObjectKey(p),
                child: _ProofTile(
                  proof: p,
                  onRemove: _submitting ? null : () => _removeProof(p),
                  onRetry: () => _upload(p),
                ),
              ),
            ),
          if (ai != null) ...[
            const SizedBox(height: 4),
            _ReadCard(read: ai),
          ],
          for (final w in warnings) ...[
            const SizedBox(height: 10),
            PsNote(message: w),
          ],
          if (_proofs.length < _maxProofs) ...[
            const SizedBox(height: 12),
            const PsSectionLabel('Add another proof'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.photo_camera_rounded, size: 19),
                    label: const Text('Take photo'),
                    style: _addStyle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseFile,
                    icon: const Icon(Icons.upload_file_rounded, size: 19),
                    label: const Text('Choose file'),
                    style: _addStyle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  static final _addStyle = OutlinedButton.styleFrom(
    foregroundColor: psBrand,
    backgroundColor: Colors.white,
    minimumSize: const Size(0, 46),
    side: const BorderSide(color: psBrandSoft, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(psRadiusControl)),
    textStyle: const TextStyle(fontFamily: psFont, fontSize: 14, fontWeight: FontWeight.w700),
  );

  // 4 · Details
  Widget _detailsStep() {
    final c = _customer!, pf = _proforma!;
    final ai = _ai;
    final modes = ref.watch(psPaymentModesProvider);
    final options = (modes.value?.isNotEmpty ?? false) ? modes.value! : _fallbackModes;
    final modeValue = options.any((m) => m.value.toLowerCase() == _mode) ? _mode : null;
    final amountFromProof = ai != null && ai.amount > 0 && (_amountValue - ai.amount).abs() < 0.005;
    final mismatch = ai != null && ai.amount > 0 && _amount.text.trim().isNotEmpty && !amountFromProof;
    final dateFromProof = ai?.txnDate != null && _date != null && DateUtils.isSameDay(ai!.txnDate, _date);
    final refFromProof = ai != null && ai.txnRef.isNotEmpty && _reference.text.trim() == ai.txnRef;
    final bankFromProof = ai != null && ai.payerBank.isNotEmpty && _bank.text.trim() == ai.payerBank;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // What it's for
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(color: psTint, borderRadius: BorderRadius.circular(psRadius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.companyName,
                  style: const TextStyle(fontFamily: psFont, fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Proforma', style: TextStyle(fontFamily: psFont, fontSize: 11.5, color: psMuted)),
                        Text(pf.invoiceNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: psMono.copyWith(fontSize: 13, color: psBody)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Open', style: TextStyle(fontFamily: psFont, fontSize: 11.5, color: psMuted)),
                      Text(formatRupees(pf.claimable),
                          style: const TextStyle(fontFamily: psFont, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PsFieldLabel('Amount received', required: true, fromProof: amountFromProof),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: psFont, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: psInput(
            hint: '0',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12, right: 4),
              child: Text('₹', style: TextStyle(fontFamily: psFont, fontSize: 16, color: psSubtle)),
            ),
            error: _tried ? _amountError : null,
          ).copyWith(prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)),
        ),
        if (!_tried || _amountError == null)
          PsHelperText('Up to ${formatRupees(pf.claimable)} (open on this proforma)'),
        if (mismatch) ...[
          const SizedBox(height: 8),
          PsNote(
            message: 'Amount on the proof is ${formatRupees(ai.amount)} but you entered ${formatRupees(_amountValue)}.',
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PsFieldLabel('Payment date', required: true, fromProof: dateFromProof, compact: true),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(psRadiusControl),
                    child: InputDecorator(
                      decoration: psInput(
                        hint: 'Pick date',
                        error: _tried && _date == null ? 'Pick the date' : null,
                        suffix: const Icon(Icons.event_rounded, color: psSubtle, size: 20),
                      ),
                      isEmpty: _date == null,
                      child: Text(psDate(_date),
                          style: const TextStyle(fontFamily: psFont, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PsFieldLabel('Mode'),
                  DropdownButtonFormField<String>(
                    initialValue: modeValue,
                    isExpanded: true,
                    hint: const Text('Select', style: TextStyle(fontFamily: psFont, color: psMuted)),
                    decoration: psInput(),
                    borderRadius: BorderRadius.circular(psRadiusControl),
                    items: [
                      for (final m in options)
                        DropdownMenuItem(
                          value: m.value.toLowerCase(),
                          child: Text(m.label.isEmpty ? paymentModeLabel(m.value) : m.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: psFont, fontSize: 15, fontWeight: FontWeight.w600, color: psInk)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _mode = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PsFieldLabel('Reference (UTR / UPI Ref / cheque no.)', fromProof: refFromProof),
        TextField(
          controller: _reference,
          onChanged: (_) => setState(() => _referenceError = null),
          textCapitalization: TextCapitalization.characters,
          style: psMono.copyWith(fontSize: 15, color: psInk),
          decoration: psInput(hint: 'e.g. 632412345678', error: _referenceError),
        ),
        const SizedBox(height: 16),
        PsFieldLabel("Payer's bank", fromProof: bankFromProof),
        TextField(
          controller: _bank,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontFamily: psFont, fontSize: 15),
          decoration: psInput(hint: 'e.g. State Bank of India'),
        ),
        const SizedBox(height: 16),
        const PsFieldLabel('Notes for accounts'),
        TextField(
          controller: _notes,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontFamily: psFont, fontSize: 15),
          decoration: psInput(hint: 'e.g. paid by the correspondent'),
        ),
        if (_tried && _stored.isEmpty) ...[
          const SizedBox(height: 14),
          const PsNote(message: 'Add at least one proof (go back to the Proof step).', error: true),
        ],
        if (_serverError != null && _referenceError == null) ...[
          const SizedBox(height: 14),
          PsNote(message: _serverError!, error: true),
        ],
      ],
    );
  }
}

// MARK: - Widgets

class _SchoolRow extends StatelessWidget {
  final PsCustomer customer;
  final bool selected;
  final VoidCallback onTap;

  const _SchoolRow({required this.customer, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final count = '${c.proformaCount} pending proforma${c.proformaCount == 1 ? '' : 's'}';
    return PsCard(
      onTap: onTap,
      selected: selected,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.companyName,
                    style: const TextStyle(fontFamily: psFont, fontSize: 14, height: 1.3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(children: [
                    if (c.dashboardId.isNotEmpty) TextSpan(text: '#${c.dashboardId}', style: psMono),
                    if (c.dashboardId.isNotEmpty) const TextSpan(text: ' · '),
                    TextSpan(text: count),
                  ]),
                  style: const TextStyle(fontFamily: psFont, fontSize: 12, color: psSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Pending', style: TextStyle(fontFamily: psFont, fontSize: 11, color: psMuted)),
              Text(formatRupees(c.pendingTotal),
                  style: const TextStyle(fontFamily: psFont, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF939DAE)),
        ],
      ),
    );
  }
}

class _SelectedSchool extends StatelessWidget {
  final PsCustomer customer;
  final VoidCallback onChange;
  const _SelectedSchool({required this.customer, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(color: psTint, borderRadius: BorderRadius.circular(psRadiusControl)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.companyName,
                      style: const TextStyle(fontFamily: psFont, fontSize: 14, fontWeight: FontWeight.w700)),
                  if (customer.dashboardId.isNotEmpty)
                    Text('#${customer.dashboardId}', style: psMono.copyWith(fontSize: 12, color: psSubtle)),
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(foregroundColor: psBrand),
              child: const Text('Change', style: TextStyle(fontFamily: psFont, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _ProformaCard extends StatelessWidget {
  final PsProforma proforma;
  final bool selected;
  final VoidCallback onTap;

  const _ProformaCard({required this.proforma, required this.selected, required this.onTap});

  Widget _line(String k, String v, {Color color = psSubtle, bool bold = false}) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(k,
                  style: TextStyle(
                      fontFamily: psFont,
                      fontSize: bold ? 14 : 12.5,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                      color: bold ? psInk : color)),
            ),
            Text(v,
                style: TextStyle(
                    fontFamily: psFont,
                    fontSize: bold ? 14 : 12.5,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: bold ? psInk : color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = proforma;
    final meta = [psDate(p.invoiceDate), p.period].where((e) => e.isNotEmpty).join(' · ');
    return Semantics(
      selected: selected,
      child: PsCard(
        onTap: onTap,
        selected: selected,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? psBrand : const Color(0xFF939DAE), width: selected ? 6 : 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.invoiceNumber, style: psMono.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: psInk)),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: const TextStyle(fontFamily: psFont, fontSize: 12, color: psMuted)),
                  ],
                  const SizedBox(height: 6),
                  _line('Total', formatRupees(p.total)),
                  if (p.submittedPending > 0) _line('Awaiting bank', '− ${formatRupees(p.submittedPending)}', color: psWarn),
                  _line('Open to submit', formatRupees(p.claimable), bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(psRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(psRadius),
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(psRadius),
              border: Border.all(color: psBrandSoft, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: psTint, shape: BoxShape.circle),
                  child: Icon(icon, color: psBrand, size: 24),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontFamily: psFont, fontSize: 14, fontWeight: FontWeight.w700, color: psBrand)),
              ],
            ),
          ),
        ),
      );
}

/// File name, upload / read progress or result, remove button.
class _ProofTile extends StatelessWidget {
  final _Proof proof;
  final VoidCallback? onRemove;
  final VoidCallback onRetry;

  const _ProofTile({required this.proof, required this.onRemove, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = proof;
    final r = p.read;
    final (status, color) = p.error != null
        ? ("Couldn't upload · ${p.error}", psDanger)
        : p.busy
            ? (p.reading ? 'Reading the proof…' : 'Uploading ${(p.progress * 100).round()}%', psBrand)
            : r == null
                ? ('Uploaded', psSuccess)
                : r.isOk
                    ? ('Read by AI · ${(r.confidence * 100).round()}% sure', psSuccess)
                    : r.notAProof
                        ? ("This doesn't look like a payment proof", psDanger)
                        : ("Uploaded · couldn't read it, type the details next", psWarn);

    return PsCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: p.isPdf
                      ? Container(
                          color: psDangerBg,
                          child: const Icon(Icons.picture_as_pdf_rounded, color: psDanger),
                        )
                      : Image.file(
                          File(p.path),
                          fit: BoxFit.cover,
                          cacheWidth: 144,
                          errorBuilder: (_, _, _) => Container(
                            color: psTint,
                            child: const Icon(Icons.image_rounded, color: psBrand),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: psMono.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: psInk)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (p.busy) ...[
                          const SizedBox(
                              width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 6),
                        ] else if (color == psSuccess) ...[
                          const Icon(Icons.check_circle_rounded, size: 14, color: psSuccess),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(status,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: psFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (p.error != null)
                IconButton(
                  tooltip: 'Retry',
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, color: psBrand),
                ),
              IconButton(
                tooltip: 'Remove proof',
                onPressed: p.busy ? null : onRemove,
                icon: const Icon(Icons.close_rounded, color: psMuted),
              ),
            ],
          ),
          if (p.busy && !p.reading)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 10, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: p.progress, minHeight: 4, backgroundColor: psTint),
              ),
            ),
        ],
      ),
    );
  }
}

/// What the AI read from the proof.
class _ReadCard extends StatelessWidget {
  final PsExtraction read;
  const _ReadCard({required this.read});

  @override
  Widget build(BuildContext context) {
    final r = read;
    final paidBy = [r.payerName, r.payerBank].where((e) => e.isNotEmpty).join(' · ');
    final paidTo = [r.payeeName, r.payeeAccount].where((e) => e.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: psTint,
        borderRadius: BorderRadius.circular(psRadius),
        border: Border.all(color: psBrandSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: psBrand),
              SizedBox(width: 6),
              Text('Read from the proof',
                  style: TextStyle(fontFamily: psFont, fontSize: 13, fontWeight: FontWeight.w700, color: psBrand)),
            ],
          ),
          const SizedBox(height: 6),
          PsKeyValue(label: 'Reference', value: r.txnRef, mono: true),
          PsKeyValue(label: 'Amount', value: r.amount > 0 ? formatRupees(r.amount) : ''),
          PsKeyValue(label: 'Date', value: psDate(r.txnDate)),
          PsKeyValue(label: 'Mode', value: paymentModeLabel(r.paymentMode)),
          if (paidBy.isNotEmpty) PsKeyValue(label: 'Paid by', value: paidBy),
          if (paidTo.isNotEmpty) PsKeyValue(label: 'Paid to', value: paidTo),
        ],
      ),
    );
  }
}
