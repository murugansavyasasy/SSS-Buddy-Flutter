import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class OverallTripViewmodel extends AsyncNotifier<List<Overalltripdetailsmodel>> {
  List<Overalltripdetailsmodel> _all = [];

  @override
  Future<List<Overalltripdetailsmodel>> build() async {
    print('📌 OverallTripViewmodel build() called');
    return [];
  }

  Future<void> loadForMember(int idMember) async {
    print('📡 loadForMember CALLED → ID: $idMember');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(idMember));
  }

  Future<List<Overalltripdetailsmodel>> _fetch(int idMember) async {
    print('🔌 _fetch STARTED for member $idMember');


    final repo = ref.read(repositoryProvider);
    print('✅ Calling repo.getoveralldetails(UserId: $idMember)');

    final response = await repo.getoveralldetails(idMember.toString());
    _all = response;

    print('📦 API SUCCESS → Received ${response.length} trips');
    return response;
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }
    final lower = query.toLowerCase();
    state = AsyncData(
      _all.where((item) => item.username.toLowerCase().contains(lower)).toList(),
    );
  }
}

final overallTripProvider =
AsyncNotifierProvider<OverallTripViewmodel, List<Overalltripdetailsmodel>>(
  OverallTripViewmodel.new,
);