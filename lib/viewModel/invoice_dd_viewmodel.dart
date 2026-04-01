import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/InvoiceModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class InvoiceDdViewmodel extends AsyncNotifier<List<Invoicemodel>> {
  List<Invoicemodel>? _cache;
  String? _lastCustomerId;

  @override
  Future<List<Invoicemodel>> build() async => [];

  Future<void> fetchForCustomer(String customerId) async {
    if (_lastCustomerId == customerId && _cache != null) {
      state = AsyncData(_cache!);
      return;
    }

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final loginData = ref.read(loginProvider).value;
      if (loginData == null) return [];

      final repo = ref.read(repositoryProvider);
      final response = await repo.getinvoicevalue(customerId);
      _cache = response;
      _lastCustomerId = customerId;
      return response;
    });
  }

  void clear() {
    _cache = null;
    _lastCustomerId = null;
    state = const AsyncData([]);
  }
}

final invoiceProvider =
    AsyncNotifierProvider<InvoiceDdViewmodel, List<Invoicemodel>>(
      InvoiceDdViewmodel.new,
    );
