import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/InvoiceModel.dart';

import '../auth/model/FinancialYearModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

// ---------------------------------------------------------------------------
// Invoice
// ---------------------------------------------------------------------------

class InvoiceDdViewmodel extends AsyncNotifier<List<Invoicemodel>> {
  List<Invoicemodel>? _invoiceCache;
  String? _lastCustomerId;

  @override
  Future<List<Invoicemodel>> build() async => [];

  Future<void> fetchForCustomer(String customerId) async {
    if (_lastCustomerId == customerId && _invoiceCache != null) {
      state = AsyncData(_invoiceCache!);
      return;
    }

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final loginData = ref.read(loginProvider).value;

      if (loginData == null) {
        return [];
      }

      final repo = ref.read(repositoryProvider);

      final response = await repo.getinvoicevalue(customerId);

      _invoiceCache = response;
      _lastCustomerId = customerId;

      return response;
    });
  }

  void clear() {
    _invoiceCache = null;
    _lastCustomerId = null;
    state = const AsyncData([]);
  }
}

final invoiceProvider =
AsyncNotifierProvider<InvoiceDdViewmodel, List<Invoicemodel>>(
  InvoiceDdViewmodel.new,
);

// ---------------------------------------------------------------------------
// Payment Mode
// Kept in this file per request, but as its own AsyncNotifier so Riverpod
// actually tracks the state and widgets rebuild when data arrives.
// ---------------------------------------------------------------------------

class PaymentModeViewmodel extends AsyncNotifier<List<Paymentmodemodel>> {
  List<Paymentmodemodel>? _cache;

  @override
  Future<List<Paymentmodemodel>> build() async {
    if (_cache != null) return _cache!;
    return _fetch();
  }

  Future<List<Paymentmodemodel>> _fetch() async {
    final loginData = ref.read(loginProvider).value;

    if (loginData == null) {
      return [];
    }

    final repo = ref.read(repositoryProvider);
    final response = await repo.getPaymentMode(loginData.token);

    _cache = response;
    return response;
  }

  Future<void> refresh() async {
    _cache = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void clear() {
    _cache = null;
    state = const AsyncData([]);
  }
}

final paymentModeProvider =
AsyncNotifierProvider<PaymentModeViewmodel, List<Paymentmodemodel>>(
  PaymentModeViewmodel.new,
);