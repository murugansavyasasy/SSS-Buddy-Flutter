import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as client;
import '../auth/model/po_details_modal.dart';
import '../provider/app_providers.dart';
import '../repository/app_endpoint.dart';
import 'login_view_model.dart';

class PoDetailsViewmodel extends AsyncNotifier<List<PoDetailsModel>> {

  @override
  Future<List<PoDetailsModel>> build() async => [];

  Future<void> getPoDetails(String purchaseOrderId) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;

      if (loginData == null) {
        state = AsyncError("User not logged in", StackTrace.current);
        return;
      }

      final response = await repo.getpodetails(
        loginData.VimsIdUser,
        purchaseOrderId,
      );

      state = AsyncData(response);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final poDetailsProvider =
AsyncNotifierProvider<PoDetailsViewmodel, List<PoDetailsModel>>(
      () => PoDetailsViewmodel(),
);