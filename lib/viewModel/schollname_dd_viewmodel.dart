import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/SchoolNameModel.dart';

import '../auth/model/SchoolNameModel.dart';
import 'customer_details_viewmodel.dart';

final schoolnameProvider =
AsyncNotifierProvider<
    SchollnameDdViewmodel,
    List<Schoolnamemodel>
>(
      () => SchollnameDdViewmodel(),
);

class SchollnameDdViewmodel
    extends AsyncNotifier<List<Schoolnamemodel>> {
  List<Schoolnamemodel> _localSchools = [];

  @override
  Future<List<Schoolnamemodel>> build() async {
    final schools = await _fetchSchools();
    _localSchools = schools;
    return schools;
  }

  // Initial 500 schools
  Future<List<Schoolnamemodel>> _fetchSchools() async {
    try {
      final customers =
      await ref.read(customerviewProvider.future);

      return customers.map((customer) {
        return Schoolnamemodel(
          CustomerID: customer.id.toString(),
          CustomerName: customer.companyName,
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Failed to load school names: $e',
      );
    }
  }

  // Search school
  Future<void> searchSchool(String query) async {
    final searchText = query.trim();
    if (searchText.isEmpty) {
      state = AsyncData(List<Schoolnamemodel>.from(_localSchools));

      return;
    }
    final localResults = _localSchools.where((school) {
      final name = school.CustomerName?.toLowerCase() ?? '';

      return name.contains(searchText.toLowerCase());
    }).toList();
    // Found locally
    if (localResults.isNotEmpty) {
      state = AsyncData(localResults);

      return;
    }
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref
          .read(customerviewProvider.notifier)
          .filter(searchText);
      final apiCustomers =
          ref.read(customerviewProvider).value ?? [];

      return apiCustomers.map((customer) {
        return Schoolnamemodel(
          CustomerID: customer.id.toString(),
          CustomerName: customer.companyName,
        );
      }).toList();
    });
    state = result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(customerviewProvider.notifier).refreshList();

      final customers = ref.read(customerviewProvider).value ?? [];

      final schools = customers.map((customer) {
        return Schoolnamemodel(
          CustomerID: customer.id.toString(),
          CustomerName: customer.companyName,
        );
      }).toList();
      _localSchools = schools;

      return schools;
    });
  }
}