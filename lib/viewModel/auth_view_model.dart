import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/Versioncheck.dart';
import '../provider/app_providers.dart';
import '../repository/app_url.dart';

class AuthViewModel extends AsyncNotifier<Versioncheck> {
  @override
  Future<Versioncheck> build() async {
    final repo = ref.read(repositoryProvider);
    final dioClient = ref.read(dioProvider);

    final value = await repo.getVersionCheckDetails();
    AppUrl.vimsUrl = value.VimsURL;
    AppUrl.schoolUrl = value.SchoolURL;

    dioClient.dio.options.baseUrl = value.VimsURL;
    return value;
  }
}

final authProvider = AsyncNotifierProvider<AuthViewModel, Versioncheck>(
  () => AuthViewModel(),
);
