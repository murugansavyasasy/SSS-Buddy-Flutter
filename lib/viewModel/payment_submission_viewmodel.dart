import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/FinancialYearModel.dart';
import '../auth/model/PaymentSubmissionModel.dart';
import '../provider/app_providers.dart';
import '../repository/payment_submission_repository.dart';

final paymentSubmissionRepositoryProvider = Provider<PaymentSubmissionRepository>(
  (ref) => PaymentSubmissionRepository(ref.read(dioProvider)),
);

/// Failures show a Retry state instead of retrying silently.
Duration? _noRetry(int retryCount, Object error) => null;

/// False when the user's role can't use Payment Submissions (403); the
/// dashboard hides the menu then.
final paymentSubmissionAccessProvider = FutureProvider<bool>(
  retry: _noRetry,
  (ref) => ref.read(paymentSubmissionRepositoryProvider).hasAccess(),
);

/// List tabs and the status they send.
enum PsTab { all, awaitingBank, receipted, rejected }

extension PsTabX on PsTab {
  String get label => switch (this) {
        PsTab.all => 'All',
        PsTab.awaitingBank => 'Awaiting bank',
        PsTab.receipted => 'Receipted',
        PsTab.rejected => 'Rejected',
      };

  /// Short label for the segmented control (fits a quarter of a phone).
  String get shortLabel => this == PsTab.awaitingBank ? 'Awaiting' : label;

  String get apiStatus => switch (this) {
        PsTab.all => '',
        PsTab.awaitingBank => 'pending',
        PsTab.receipted => 'done',
        PsTab.rejected => 'rejected',
      };
}

class PsListState {
  final PsTab tab;
  final bool mine;
  final List<PaymentSubmission> items;
  final int page;
  final int totalPages;
  final bool loadingMore;

  /// A failed "load more" (the loaded rows stay).
  final Object? moreError;

  const PsListState({
    this.tab = PsTab.all,
    this.mine = true,
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.loadingMore = false,
    this.moreError,
  });

  bool get hasMore => page < totalPages;

  PsListState copyWith({
    List<PaymentSubmission>? items,
    int? page,
    int? totalPages,
    bool? loadingMore,
    Object? moreError,
    bool clearMoreError = false,
  }) =>
      PsListState(
        tab: tab,
        mine: mine,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        loadingMore: loadingMore ?? this.loadingMore,
        moreError: clearMoreError ? null : (moreError ?? this.moreError),
      );
}

/// Submissions list: tab + "Only my submissions", infinite scroll.
class PaymentSubmissionListViewModel extends AsyncNotifier<PsListState> {
  static const pageSize = 25;

  PsTab _tab = PsTab.all;
  bool _mine = true;

  /// School, dashboard id, reference or invoice no. ('' = no search).
  String _search = '';

  /// The filter being shown (also while its first page loads).
  PsTab get tab => _tab;
  bool get mine => _mine;
  String get search => _search;

  /// Bumped on every reload so a slow old page can't land in a new filter.
  int _generation = 0;

  @override
  Future<PsListState> build() => _firstPage();

  Future<PsListState> _firstPage() async {
    final gen = ++_generation;
    final page = await ref.read(paymentSubmissionRepositoryProvider).fetchSubmissions(
          status: _tab.apiStatus,
          mine: _mine,
          page: 1,
          limit: pageSize,
          search: _search,
        );
    if (gen != _generation) throw StateError('stale');
    return PsListState(
      tab: _tab,
      mine: _mine,
      items: page.items,
      page: 1,
      totalPages: page.totalPages,
    );
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    final gen = _generation + 1;
    final next = await AsyncValue.guard(_firstPage);
    if (gen == _generation) state = next;
  }

  Future<void> setTab(PsTab tab) async {
    if (tab == _tab) return;
    _tab = tab;
    await _reload();
  }

  Future<void> setMine(bool mine) async {
    if (mine == _mine) return;
    _mine = mine;
    await _reload();
  }

  Future<void> setSearch(String search) async {
    final q = search.trim();
    if (q == _search) return;
    _search = q;
    await _reload();
  }

  /// Pull to refresh: keeps the rows on screen until the new page arrives.
  Future<void> refresh() async {
    final gen = _generation + 1;
    final next = await AsyncValue.guard(_firstPage);
    if (gen == _generation) state = next;
  }

  Future<void> retry() => _reload();

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.loadingMore || !s.hasMore) return;
    final gen = _generation;
    state = AsyncData(s.copyWith(loadingMore: true, clearMoreError: true));
    try {
      final page = await ref.read(paymentSubmissionRepositoryProvider).fetchSubmissions(
            status: _tab.apiStatus,
            mine: _mine,
            page: s.page + 1,
            limit: pageSize,
            search: _search,
          );
      if (gen != _generation) return;
      final seen = {for (final i in s.items) i.id};
      state = AsyncData(s.copyWith(
        items: [...s.items, ...page.items.where((i) => !seen.contains(i.id))],
        page: s.page + 1,
        totalPages: page.totalPages,
        loadingMore: false,
      ));
    } catch (e) {
      if (gen != _generation) return;
      state = AsyncData(s.copyWith(loadingMore: false, moreError: e));
    }
  }
}

final paymentSubmissionListProvider =
    AsyncNotifierProvider.autoDispose<PaymentSubmissionListViewModel, PsListState>(
  PaymentSubmissionListViewModel.new,
  retry: _noRetry,
);

/// Schools with a pending proforma, filtered by [search].
final psCustomersProvider = FutureProvider.autoDispose.family<List<PsCustomer>, String>(
  retry: _noRetry,
  (ref, search) => ref.read(paymentSubmissionRepositoryProvider).fetchCustomers(search: search),
);

/// Open proformas of a school.
final psProformasProvider = FutureProvider.autoDispose.family<List<PsProforma>, int>(
  retry: _noRetry,
  (ref, customerId) => ref.read(paymentSubmissionRepositoryProvider).fetchProformas(customerId),
);

/// Mode dropdown values; kept for the session.
final psPaymentModesProvider = FutureProvider<List<Paymentmodemodel>>(
  retry: _noRetry,
  (ref) => ref.read(paymentSubmissionRepositoryProvider).fetchPaymentModes(),
);

final paymentSubmissionDetailProvider = FutureProvider.autoDispose.family<PaymentSubmission, int>(
  retry: _noRetry,
  (ref, id) => ref.read(paymentSubmissionRepositoryProvider).fetchSubmission(id),
);
