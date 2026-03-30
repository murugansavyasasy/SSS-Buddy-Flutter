import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/FinancialYearModel.dart';

import '../provider/app_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/FinancialYearModel.dart';
import '../provider/app_providers.dart';

class FinancialyearDdViewmodel extends AsyncNotifier<List<Financialyearmodel>> {
  List<Financialyearmodel>? _cache;

  @override
  Future<List<Financialyearmodel>> build() async {
    if (_cache != null) return _cache!;
    return _fetch();
  }

  Future<List<Financialyearmodel>> _fetch() async {
    final repo = ref.read(repositoryProvider);
    final response = await repo.getfinancialyear();
    _cache = response;
    return response;
  }

  Future<void> refresh() async {
    _cache = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final financialyearProvider =
AsyncNotifierProvider<FinancialyearDdViewmodel, List<Financialyearmodel>>(
  FinancialyearDdViewmodel.new,
);