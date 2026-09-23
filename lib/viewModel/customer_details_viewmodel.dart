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

  bool get hasMore => _page < _totalPages;

  @override
  Future<List<Customerdetailsmodel>> build() async {
    _page = 1;
    _searchQuery = '';
    final response = await _fetchPage(_page);
    _all = response.data;
    _totalPages = response.totalPages;
    return _all;
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    if (ref.read(isLoadingMoreProvider)) return;

    ref.read(isLoadingMoreProvider.notifier).state = true;

    try {
      final nextPage = _page + 1;
      final response = await _fetchPage(nextPage);
      _all = [..._all, ...response.data];
      _page = nextPage;
      _totalPages = response.totalPages;
      state = AsyncData(_all);
    } finally {
      ref.read(isLoadingMoreProvider.notifier).state = false;
    }
  }

  // Now calls API instead of local filtering
  Future<void> filter(String query) async {
    _searchQuery = query;
    _page = 1;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _fetchPage(_page);
      _all = response.data;
      _totalPages = response.totalPages;
      return _all;
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
  Future<void> refreshList() async {
    _searchQuery = '';
    _page = 1;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _fetchPage(_page);
      _all = response.data;
      _totalPages = response.totalPages;
      return _all;
    });
  }

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