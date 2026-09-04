import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sssbuddy/auth/model/CustomerdetailsModel.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

import '../provider/app_providers.dart';

class CustomerDetailsViewmodel
    extends AsyncNotifier<List<Customerdetailsmodel>> {

  List<Customerdetailsmodel> _all = [];
  int _page = 1;
  final int _limit = 25;
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
      state = AsyncData(_searchQuery.isEmpty ? _all : _filtered());
    } finally {
      ref.read(isLoadingMoreProvider.notifier).state = false;
    }
  }

  void filter(String query) {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }

    state = AsyncData(_filtered());
  }

  List<Customerdetailsmodel> _filtered() {
    final lower = _searchQuery.toLowerCase();
    return _all.where((item) {
      return item.companyName.toLowerCase().contains(lower) ||
          item.accountManager.toLowerCase().contains(lower);
    }).toList();
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

    return repo.getCustomersList(loginData.token, page: page, limit: _limit);
  }
}

final customerviewProvider =
AsyncNotifierProvider<CustomerDetailsViewmodel,
    List<Customerdetailsmodel>>(
      () => CustomerDetailsViewmodel(),
);

final isLoadingMoreProvider = StateProvider<bool>((ref) => false);