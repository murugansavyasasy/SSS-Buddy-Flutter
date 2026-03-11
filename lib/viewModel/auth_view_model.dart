import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/Versioncheck.dart';
import '../provider/app_providers.dart';

class AuthViewModel extends AsyncNotifier<Versioncheck> {
  @override
  Future<Versioncheck> build() async {
    final repo = ref.read(repositoryProvider);

    return await repo.getVersionCheckDetails();
  }
}

final authProvider = AsyncNotifierProvider<AuthViewModel, Versioncheck>(
  () => AuthViewModel(),
);
