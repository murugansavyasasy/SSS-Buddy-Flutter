import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sssbuddy/auth/model/CustomerdetailsModel.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

import '../provider/app_providers.dart';

class CustomerDetailsViewmodel
    extends AsyncNotifier<List<Customerdetailsmodel>> {

  List<Customerdetailsmodel> _all = [];
  int _page = 1;
  final int _limit = 100;
  int _totalPages = 1;
  String _searchQuery = '';

  // Bumped on every new search/refresh so responses from an older request
  // (typed-ahead query, or a loadMore still in flight) are dropped.
  int _requestId = 0;

  bool get hasMore => _page < _totalPages;

  @override
  Future<List<Customerdetailsmodel>> build() async {
    _page = 1;
    _searchQuery = '';
    _requestId++;
    final response = await _fetchPage(_page);
    _all = response.data;
    _totalPages = response.totalPages;
    return _visible();
  }

  /// Applies the search query locally as well, so the list matches what was
  /// typed even when the server returns unfiltered rows.
  List<Customerdetailsmodel> _visible() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _all;
    bool has(String? v) => v != null && v.toLowerCase().contains(q);
    return _all
        .where((c) =>
            has(c.companyName) ||
            has(c.customerName) ||
            has(c.invoiceName) ||
            has(c.customerCode) ||
            has(c.city) ||
            has(c.contactPerson) ||
            has(c.contactNumber))
        .toList();
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    if (ref.read(isLoadingMoreProvider)) return;

    ref.read(isLoadingMoreProvider.notifier).state = true;

    final requestId = _requestId;
    try {
      final nextPage = _page + 1;
      final response = await _fetchPage(nextPage);
      if (requestId != _requestId) return; // search changed meanwhile
      _all = [..._all, ...response.data];
      _page = nextPage;
      _totalPages = response.totalPages;
      state = AsyncData(_visible());
    } catch (e) {
      // Keep the rows already shown; the next scroll will retry.
    } finally {
      ref.read(isLoadingMoreProvider.notifier).state = false;
    }
  }

  /// Searches on the server (and locally on the returned rows).
  Future<void> filter(String query) async {
    if (query.trim() == _searchQuery.trim() && state.hasValue && !state.isLoading) {
      return;
    }
    await _reload(query);
  }

  Future<void> _reload(String query) async {
    _searchQuery = query;
    _page = 1;
    final requestId = ++_requestId;
    ref.read(isLoadingMoreProvider.notifier).state = false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _fetchPage(1));
    if (requestId != _requestId) return; // a newer search replaced this one

    state = result.whenData((response) {
      _all = response.data;
      _totalPages = response.totalPages;
      return _visible();
    });
  }

  // ============================================================
  // REFRESH LIST — called every time the Customer List page opens.
  // ============================================================
  //
  // customerviewProvider is a plain AsyncNotifierProvider (not
  // autoDispose), so it stays alive and keeps its old search query /
  // page across navigations. Without this, re-opening the page just
  // showed whatever was cached from the last visit (possibly still
  // filtered) instead of doing a fresh call.
  //
  // This always resets the search box + pagination and re-fetches
  // page 1 from the server, regardless of what the previous state was.
  Future<void> refreshList() => _reload('');

  Future<CustomerListResponse> _fetchPage(int page) async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) {
      return CustomerListResponse(
        data: [],
        page: page,
        limit: _limit,
        total: 0,
        totalPages: page,
      );
    }

    final repo = ref.read(repositoryProvider);

    return repo.getCustomersList(
      loginData.token,
      page: page,
      limit: _limit,
      search: _searchQuery,
    );
  }
}

final customerviewProvider =
AsyncNotifierProvider<CustomerDetailsViewmodel,
    List<Customerdetailsmodel>>(
      () => CustomerDetailsViewmodel(),
);

final isLoadingMoreProvider = StateProvider<bool>((ref) => false);