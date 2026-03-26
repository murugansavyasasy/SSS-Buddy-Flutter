import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ImportantInfoModel.dart';
import '../provider/app_providers.dart';

import 'login_view_model.dart';

class ImportantInfoViewModel extends AsyncNotifier<Importantinfomodel?> {
  @override
  Future<Importantinfomodel?> build() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;
    if (loginData == null) return null;

    final repo = ref.read(repositoryProvider);
    final response = await repo.getImportantInfo();
    return response.firstOrNull;
  }
}

final importantinfoviewprovider =
    AsyncNotifierProvider<ImportantInfoViewModel, Importantinfomodel?>(
      () => ImportantInfoViewModel(),
    );
