import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class OverallTripViewmodel
    extends AsyncNotifier<List<Overalltripdetailsmodel>> {
  List<Overalltripdetailsmodel> _all = [];

  @override
  Future<List<Overalltripdetailsmodel>> build() async {
    print('📌 OverallTripViewmodel build() called');
    return [];
  }

  Future<void> loadForMember(int idMember) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(idMember));
  }

  Future<List<Overalltripdetailsmodel>> _fetch(int idMember) async {
    final loginData = ref.read(loginProvider).value;
    if (loginData == null) {
      throw Exception("User not logged in");
    }

    final token = loginData.token;
    final repo = ref.read(repositoryProvider);

    final response =
    await repo.getoveralldetails(token, idMember.toString());

    _all = response;
    return response;
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }
    final lower = query.toLowerCase();
    state = AsyncData(
      _all
          .where(
            (item) => item.username.toLowerCase().contains(lower),
      )
          .toList(),
    );
  }
}

final overallTripProvider =
AsyncNotifierProvider<OverallTripViewmodel, List<Overalltripdetailsmodel>>(
  OverallTripViewmodel.new,
);