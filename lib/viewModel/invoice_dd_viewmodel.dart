import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/InvoiceModel.dart';

import '../auth/model/FinancialYearModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

// ---------------------------------------------------------------------------
// Invoice
// ---------------------------------------------------------------------------

class InvoiceDdViewmodel
    extends AsyncNotifier<List<Invoicemodel>> {

  List<Invoicemodel>? _invoiceCache;
  String? _lastCustomerId;

  @override
  Future<List<Invoicemodel>> build() async {
    return [];
  }

  Future<void> fetchForCustomer(String customerId) async {
    try {
      if (_lastCustomerId == customerId &&
          _invoiceCache != null) {
        state = AsyncData(_invoiceCache!);
        return;
      }

      state = const AsyncLoading();

      final loginData = ref.read(loginProvider).value;

      if (loginData == null) {
        state = AsyncData([]);
        return;
      }

      final token = loginData.token;

      final repo = ref.read(repositoryProvider);

      final response = await repo.getPoList(
        customerId,
        token,
      );
      final invoiceList =
      response.data.pendingInvoices.map((invoice) {
        return Invoicemodel(
          InvoiceId: invoice.id.toString(),
          InvoiceNumber: invoice.invoiceNumber,
          PendingAmount: invoice.pendingAmount.toString(),
        );
      }).toList();

      _invoiceCache = invoiceList;
      _lastCustomerId = customerId;
      state = AsyncData(invoiceList);

    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );
    }
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