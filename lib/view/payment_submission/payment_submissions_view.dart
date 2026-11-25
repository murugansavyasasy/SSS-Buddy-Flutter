import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/PaymentSubmissionModel.dart';
import '../../viewModel/payment_submission_viewmodel.dart';
import 'payment_submission_detail_view.dart';
import 'payment_submit_view.dart';
import 'widget/payment_common.dart';

/// Payment submissions: what the account manager (and their team)
/// submitted and where each one stands. Entry point for "Submit payment".
class PaymentSubmissionsView extends ConsumerStatefulWidget {
  const PaymentSubmissionsView({super.key});

  @override
  ConsumerState<PaymentSubmissionsView> createState() => _PaymentSubmissionsViewState();
}

class _PaymentSubmissionsViewState extends ConsumerState<PaymentSubmissionsView> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// The search box is hidden until the header's search icon is tapped.
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(paymentSubmissionListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Calls the API only when the user taps Search (button or keyboard).
  void _runSearch() {
    _searchFocus.unfocus();
    _vm.setSearch(_search.text);
  }

  void _clearSearch() {
    _search.clear();
    setState(() {});
    _vm.setSearch('');
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  /// Hides the box and drops the search.
  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() => _searchOpen = false);
    if (_search.text.isNotEmpty || _vm.search.isNotEmpty) _clearSearch();
  }

  PaymentSubmissionListViewModel get _vm => ref.read(paymentSubmissionListProvider.notifier);

  Future<void> _openDetail(PaymentSubmission s) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentSubmissionDetailView(id: s.id, initial: s)),
    );
    if (changed == true && mounted) _vm.refresh();
  }

  Future<void> _submit() async {
    final created = await Navigator.push<PaymentSubmission>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentSubmitView()),
    );
    if (created == null || !mounted) return;
    _vm.refresh();
    await _openDetail(created);
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(paymentSubmissionListProvider);
    final tab = _vm.tab;
    final mine = _vm.mine;

    return PsTheme(
      child: Scaffold(
        backgroundColor: psPageBg,
        body: Column(
          children: [
            PsHeader(
              title: 'Payment submissions',
              trailing: IconButton(
                tooltip: _searchOpen ? 'Close search' : 'Search',
                onPressed: _searchOpen ? _closeSearch : _openSearch,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(
                    _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                    key: ValueKey(_searchOpen),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Search, tabs + "Only my submissions"
            Container(
              color: psPageBg,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_searchOpen
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: PsSearchBar(
                              controller: _search,
                              hint: 'School, reference or invoice no.',
                              focusNode: _searchFocus,
                              onChanged: () => setState(() {}),
                              onSearch: _runSearch,
                              onClear: _clearSearch,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _Segmented(
                      selected: tab,
                      onSelect: (t) => _vm.setTab(t),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: psMuted),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Only my submissions',
                              style: TextStyle(
                                  fontFamily: psFont, fontSize: 13.5, fontWeight: FontWeight.w500, color: psSubtle)),
                        ),
                        Transform.scale(
                          scale: 0.82,
                          alignment: Alignment.centerRight,
                          child: Switch(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: mine,
                            onChanged: (v) => _vm.setMine(v),
                            activeTrackColor: psBrand,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: psStrongBorder,
                            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => PsStateView.error(e, onRetry: _vm.retry),
                data: (s) => RefreshIndicator(
                  color: psBrand,
                  onRefresh: _vm.refresh,
                  child: s.items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 40),
                            if (_vm.search.isNotEmpty)
                              PsStateView(
                                icon: Icons.search_off_rounded,
                                title: 'No match',
                                message: 'Nothing matches “${_vm.search}”'
                                    '${tab == PsTab.all ? '' : ' in ${tab.label}'}.',
                                actionLabel: 'Clear search',
                                onAction: _clearSearch,
                              )
                            else
                              PsStateView(
                                icon: Icons.receipt_long_rounded,
                                title: tab == PsTab.all ? 'No submissions yet' : 'Nothing here',
                                message: tab == PsTab.all
                                    ? 'When a school pays, tap “Submit payment” and upload the proof.'
                                    : 'No ${tab.label.toLowerCase()} submissions.',
                              ),
                          ],
                        )
                      : ListView.separated(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: s.items.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            if (i == s.items.length) return _ListFooter(state: s, onRetry: _vm.loadMore);
                            return PsAppear(
                              key: ValueKey('${s.tab}-${s.mine}-${s.items[i].id}'),
                              index: i,
                              child: PaymentSubmissionCard(
                                submission: s.items[i],
                                onTap: () => _openDetail(s.items[i]),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            PsBottomBar(
              child: PsPrimaryButton(
                label: 'Submit payment',
                icon: Icons.add_rounded,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// All / Awaiting bank / Receipted / Rejected as one equal-width control
/// with a sliding white thumb.
class _Segmented extends StatelessWidget {
  final PsTab selected;
  final ValueChanged<PsTab> onSelect;

  const _Segmented({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const tabs = PsTab.values;
    final i = tabs.indexOf(selected);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: psNeutralBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: psReduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * i / (tabs.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F0E1440), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final t in tabs)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: t == selected,
                    child: InkWell(
                      onTap: () => onSelect(t),
                      borderRadius: BorderRadius.circular(9),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(t.shortLabel,
                                maxLines: 1,
                                style: TextStyle(
                                    fontFamily: psFont,
                                    fontSize: 13,
                                    fontWeight: t == selected ? FontWeight.w700 : FontWeight.w600,
                                    color: t == selected ? psBrand : psSubtle)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Spinner while the next page loads, Retry when it failed.
class _ListFooter extends StatelessWidget {
  final PsListState state;
  final VoidCallback onRetry;
  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))),
      );
    }
    if (state.moreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: psBrand),
          label: const Text("Couldn't load more · Retry",
              style: TextStyle(fontFamily: psFont, color: psBrand, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}

/// One submission: school, amount, proforma no., mode · reference · date,
/// status chip, and the receipt number or rejection reason.
class PaymentSubmissionCard extends StatelessWidget {
  final PaymentSubmission submission;
  final VoidCallback? onTap;

  const PaymentSubmissionCard({super.key, required this.submission, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = submission;
    final stage = s.stage;
    final meta = [
      paymentModeLabel(s.paymentMethod),
      if (s.referenceNumber.isNotEmpty) s.referenceNumber,
      psDate(s.paymentDate),
    ].where((e) => e.isNotEmpty).join(' · ');
    final bank = s.bankTxn;
    final (extra, extraColor) = switch (stage) {
      SubmissionStage.foundInBank => (
          'Credit of ${formatRupees(bank!.amount > 0 ? bank.amount : s.amount)}'
              '${bank.valueDate != null ? ' on ${psDate(bank.valueDate)}' : ''} — accounts to confirm',
          psWarn
        ),
      SubmissionStage.receipted =>
        (s.receiptNumber.isEmpty ? '' : 'Receipt ${s.receiptNumber}', psSuccess),
      SubmissionStage.rejected => (s.reviewNotes, psDanger),
      _ => ('', psSubtle),
    };

    return PsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(s.customerName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: psFont, fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(formatRupees(s.amount),
                  style: const TextStyle(fontFamily: psFont, fontSize: 15.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (s.invoiceNumber.isNotEmpty)
                Text(s.invoiceNumber, style: psMono.copyWith(fontSize: 12, color: psSubtle)),
              if (s.isTaxInvoice) const PsChip(label: 'Tax invoice', background: psSuccessBg, foreground: psSuccess),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDF0F5)),
          ),
          Row(
            children: [
              Expanded(
                child: Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: psFont, fontSize: 12.5, color: psMuted)),
              ),
              const SizedBox(width: 8),
              PsChip.stage(stage),
            ],
          ),
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(extra,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: psFont, fontSize: 12.5, height: 1.35, color: extraColor)),
          ],
        ],
      ),
    );
  }
}
