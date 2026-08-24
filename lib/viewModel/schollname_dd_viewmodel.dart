import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/SchoolNameModel.dart';

import 'customer_details_viewmodel.dart';

class SchollnameDdViewmodel
    extends AsyncNotifier<List<Schoolnamemodel>> {

  @override
  Future<List<Schoolnamemodel>> build() async {
    return await _fetchSchools();
  }

  Future<List<Schoolnamemodel>> _fetchSchools() async {
    try {
      // Customer API already handled by customerviewProvider
      final customers =
      await ref.watch(customerviewProvider.future);

      // Convert CustomerDetailsModel
      // to SchoolNameModel
      final schools = customers.map((customer) {
        return Schoolnamemodel(
          CustomerID: customer.id.toString(),
          CustomerName: customer.companyName,
        );
      }).toList();

      return schools;
    } catch (e, stackTrace) {
      throw Exception(
        'Failed to load school names: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      ref.invalidate(customerviewProvider);
      final customers =
      await ref.read(customerviewProvider.future);
      return customers.map((customer) {
        return Schoolnamemodel(
          CustomerID: customer.id.toString(),
          CustomerName: customer.companyName,
        );
      }).toList();
    });
  }
}

final schoolnameProvider =
AsyncNotifierProvider<
    SchollnameDdViewmodel,
    List<Schoolnamemodel>
>(
      () => SchollnameDdViewmodel(),
);