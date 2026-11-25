import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/model/PaymentSubmissionModel.dart';
import '../../core/network/DioClient.dart';
import '../../provider/user_session_provider.dart';
import '../../viewModel/payment_submission_viewmodel.dart';
import 'widget/payment_common.dart';

/// One submission: amount and status, progress from submitted to receipted,
/// the payment details and proofs. The submitter can withdraw it while it is
/// pending. Pops with true when it was withdrawn.
class PaymentSubmissionDetailView extends ConsumerStatefulWidget {
  final int id;

  /// The list row, shown while the detail loads.
  final PaymentSubmission? initial;

  const PaymentSubmissionDetailView({super.key, required this.id, this.initial});

  @override
  ConsumerState<PaymentSubmissionDetailView> createState() => _PaymentSubmissionDetailViewState();
}

class _PaymentSubmissionDetailViewState extends ConsumerState<PaymentSubmissionDetailView> {
  bool _withdrawing = false;
  bool _changed = false;

  Future<void> _refresh() async {
    ref.invalidate(paymentSubmissionDetailProvider(widget.id));
    try {
      await ref.read(paymentSubmissionDetailProvider(widget.id).future);
    } catch (_) {}
  }

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw submission?', style: TextStyle(fontFamily: psFont, fontWeight: FontWeight.w700)),
        content: const Text(
          'Accounts will stop looking for this payment. Use this for a wrong school or amount, then submit again.',
          style: TextStyle(fontFamily: psFont, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it', style: TextStyle(fontFamily: psFont, color: psSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw',
                style: TextStyle(fontFamily: psFont, color: psDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _withdrawing = true);
    try {
      await ref.read(paymentSubmissionRepositoryProvider).withdraw(widget.id);
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission withdrawn')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      // 400 = no longer pending: show what it is now.
      if (e is ApiException && e.statusCode == 400) _changed = true;
    }
    await _refresh();
    if (mounted) setState(() => _withdrawing = false);
  }

  Future<void> _openProof(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the proof")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(paymentSubmissionDetailProvider(widget.id));
    final userId = ref.watch(userSessionProvider).value?.userId ?? '';
    final s = async.value ?? (async.hasError ? null : widget.initial);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: PsTheme(
        child: Scaffold(
          backgroundColor: psPageBg,
          body: Column(
            children: [
              PsHeader(
                title: 'Payment submission',
                onBack: () => Navigator.pop(context, _changed),
              ),
              Expanded(
                child: s == null
                    ? (async.hasError
                        ? PsStateView.error(
                            async.error!,
                            title: (async.error is ApiException &&
                                    (async.error as ApiException).statusCode == 404)
                                ? 'Submission not found'
                                : "Couldn't load",
                            onRetry: _refresh,
                          )
                        : const Center(child: CircularProgressIndicator()))
                    : RefreshIndicator(
                        color: psBrand,
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            PsAppear(index: 0, child: _Summary(s: s)),
                            const SizedBox(height: 20),
                            const PsSectionLabel('Progress'),
                            PsAppear(index: 1, child: _Timeline(s: s)),
                            const SizedBox(height: 20),
                            const PsSectionLabel('Payment details'),
                            PsAppear(index: 2, child: _Details(s: s, onOpenProof: _openProof)),
                            if (async.isLoading && async.hasValue == false) ...[
                              const SizedBox(height: 16),
                              const Center(
                                  child: SizedBox(
                                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
                            ],
                          ],
                        ),
                      ),
              ),
              if (s != null && async.hasValue && s.canWithdraw(userId))
                PsBottomBar(
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _withdrawing ? null : _withdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: psDanger,
                        side: const BorderSide(color: psDanger, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(psRadiusControl)),
                        textStyle: const TextStyle(fontFamily: psFont, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: _withdrawing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: psDanger))
                          : const Text('Withdraw submission'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amount, status chip, school and proforma / tax invoice number.
class _Summary extends StatelessWidget {
  final PaymentSubmission s;
  const _Summary({required this.s});

  @override
  Widget build(BuildContext context) => PsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(formatRupees(s.amount),
                      style: const TextStyle(fontFamily: psFont, fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                PsChip.stage(s.stage),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.customerName,
                style: const TextStyle(fontFamily: psFont, fontSize: 15, height: 1.3, fontWeight: FontWeight.w700)),
            if (s.invoiceNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.stage == SubmissionStage.receipted || s.isTaxInvoice
                    ? '${s.invoiceNumber} · tax invoice'
                    : s.invoiceNumber,
                style: psMono.copyWith(fontSize: 12.5, color: psSubtle),
              ),
            ],
          ],
        ),
      );
}

class _Step {
  final String title;
  final String sub;

  /// done, now, todo or bad.
  final String state;
  const _Step(this.title, this.sub, this.state);
}

/// Submitted → Found in bank statement → Receipted (or Rejected / Withdrawn).
class _Timeline extends StatelessWidget {
  final PaymentSubmission s;
  const _Timeline({required this.s});

  List<_Step> get _steps {
    final by = [
      psDateTime(s.submittedAt),
      if (s.submittedByName.isNotEmpty)
        'by ${s.submittedByName}${s.source.isNotEmpty ? ' (${s.source})' : ''}',
    ].where((e) => e.isNotEmpty).join(' · ');
    final submitted = _Step('Submitted', by, 'done');
    final reviewer = [
      if (s.reviewedByName.isNotEmpty) s.reviewedByName,
      if (s.reviewedAt != null) psDate(s.reviewedAt),
    ].join(', ');
    switch (s.stage) {
      case SubmissionStage.rejected:
        return [
          submitted,
          _Step(
            'Rejected by accounts',
            [if (s.reviewNotes.isNotEmpty) s.reviewNotes, if (reviewer.isNotEmpty) '— $reviewer'].join(' '),
            'bad',
          ),
        ];
      case SubmissionStage.withdrawn:
        return [submitted, const _Step('Withdrawn', 'Cancelled by the account manager', 'bad')];
      default:
        final b = s.bankTxn;
        final found = b != null;
        final receipted = s.stage == SubmissionStage.receipted;
        return [
          submitted,
          _Step(
            'Found in bank statement',
            found
                ? [
                    '${formatRupees(b.amount > 0 ? b.amount : s.amount)} credited'
                        '${b.valueDate != null ? ' ${psDate(b.valueDate)}' : ''}',
                    if (b.refNo.isNotEmpty) 'Ref ${b.refNo}',
                  ].join(' · ')
                : receipted
                    ? 'Matched by accounts'
                    : 'Waiting for the credit to appear in an uploaded statement',
            found || receipted ? 'done' : 'now',
          ),
          _Step(
            'Receipted',
            receipted
                ? [
                    if (s.receiptNumber.isNotEmpty) 'Receipt ${s.receiptNumber}',
                    if (s.invoiceNumber.isNotEmpty) 'proforma approved as tax invoice ${s.invoiceNumber}',
                  ].join(' · ')
                : 'Accounts confirms the match and posts the receipt',
            receipted ? 'done' : (found ? 'now' : 'todo'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    return PsCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 18,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        _Dot(state: steps[i].state),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: steps[i].state == 'done' ? psSuccess : psBorder,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].title,
                              style: TextStyle(
                                  fontFamily: psFont,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: switch (steps[i].state) {
                                    'bad' => psDanger,
                                    'now' => psBrand,
                                    'todo' => psMuted,
                                    _ => s.stage == SubmissionStage.receipted && i == steps.length - 1
                                        ? psSuccess
                                        : psInk,
                                  })),
                          if (steps[i].sub.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(steps[i].sub,
                                style: const TextStyle(
                                    fontFamily: psFont, fontSize: 12.5, height: 1.4, color: psSubtle)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String state;
  const _Dot({required this.state});

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (state) {
            'done' => psSuccess,
            'bad' => psDanger,
            _ => Colors.white,
          },
          border: switch (state) {
            'now' => Border.all(color: psBrand, width: 4.5),
            'todo' => Border.all(color: psStrongBorder, width: 2),
            _ => null,
          },
        ),
        child: switch (state) {
          'done' => const Icon(Icons.check_rounded, size: 11, color: Colors.white),
          'bad' => const Icon(Icons.close_rounded, size: 11, color: Colors.white),
          _ => null,
        },
      );
}

/// Mode, reference, dates, payer bank, notes, AI read and the proofs.
class _Details extends StatelessWidget {
  final PaymentSubmission s;
  final ValueChanged<String> onOpenProof;
  const _Details({required this.s, required this.onOpenProof});

  @override
  Widget build(BuildContext context) {
    final ai = s.extraction;
    final aiRead = ai == null || !ai.isOk
        ? ''
        : [
            if (ai.amount > 0) formatRupees(ai.amount),
            if (ai.txnDate != null) psDate(ai.txnDate),
            if (ai.payerName.isNotEmpty) ai.payerName,
          ].join(' · ');
    return PsCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PsKeyValue(label: 'Mode', value: paymentModeLabel(s.paymentMethod)),
          PsKeyValue(label: 'Reference', value: s.referenceNumber, mono: true),
          PsKeyValue(label: 'Paid on', value: psDate(s.paymentDate)),
          PsKeyValue(label: 'Payer bank', value: s.payerBank),
          if (s.notes.isNotEmpty) PsKeyValue(label: 'Notes', value: s.notes),
          if (aiRead.isNotEmpty) PsKeyValue(label: 'AI read', value: aiRead),
          if (s.supportingDocs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < s.supportingDocs.length; i++)
                  ActionChip(
                    onPressed: () => onOpenProof(s.supportingDocs[i]),
                    avatar: Icon(
                      s.supportingDocs[i].toLowerCase().split('?').first.endsWith('.pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      size: 18,
                      color: psBrand,
                    ),
                    label: Text(s.supportingDocs.length == 1 ? 'Proof' : 'Proof ${i + 1}',
                        style: const TextStyle(fontFamily: psFont, fontWeight: FontWeight.w600, color: psBrand)),
                    backgroundColor: psTint,
                    side: const BorderSide(color: psBrandSoft),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(psRadiusControl)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
