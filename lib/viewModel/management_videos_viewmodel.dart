import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ManagementVideosModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class ManagementVideosViewmodel
    extends AsyncNotifier<List<Managementvideosmodel>> {
  @override
  Future<List<Managementvideosmodel>> build() async {
    return managementvideosmodel();
  }

  Future<List<Managementvideosmodel>> managementvideosmodel() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final vimIdUSer = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getmanagementvideos(vimIdUSer);

    return response;
  }
}

final managementVideosProvider =
AsyncNotifierProvider<ManagementVideosViewmodel, List<Managementvideosmodel>>(
      () => ManagementVideosViewmodel(),
);


