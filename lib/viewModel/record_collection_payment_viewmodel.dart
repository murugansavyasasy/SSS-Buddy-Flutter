import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/RecordCollectionPaymentResponse.dart';
import '../provider/app_providers.dart';

class RecordCollectionPaymentViewmodel
    extends AsyncNotifier<Recordcollectionpaymentresponse?> {
  @override
  Future<Recordcollectionpaymentresponse?> build() async => null;

  /// Submits a payment record with an optional image attachment (multipart).
  Future<bool> createPayment({
    required String invoiceID,
    required String customerId,
    required String financialYear,
    required String invoiceNumber,
    required String received,
    required String receivedDate,
    required String paymentMode,
    required String createdBy,
    required String cashRecdDate,
    required String chequeDate,
    required String chequeNumber,
    required String neftDetails,
    required String depositedBank,
    required String depositedBranch,
    required String depositedBy,
    required String depositedDate,
    File? imageFile, // optional — if null, empty file is sent like Java does
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(repositoryProvider);
      final response = await repo.createPaymentMultipart(
        invoiceID: invoiceID,
        customerId: customerId,
        financialYear: financialYear,
        invoiceNumber: invoiceNumber,
        received: received,
        receivedDate: receivedDate,
        paymentMode: paymentMode,
        createdBy: createdBy,
        cashRecdDate: cashRecdDate,
        chequeDate: chequeDate,
        chequeNumber: chequeNumber,
        neftDetails: neftDetails,
        depositedBank: depositedBank,
        depositedBranch: depositedBranch,
        depositedBy: depositedBy,
        depositedDate: depositedDate,
        imageFile: imageFile,
      );
      state = AsyncData(response);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final createPaymentProvider = AsyncNotifierProvider<
    RecordCollectionPaymentViewmodel, Recordcollectionpaymentresponse?>(
  RecordCollectionPaymentViewmodel.new,
);
