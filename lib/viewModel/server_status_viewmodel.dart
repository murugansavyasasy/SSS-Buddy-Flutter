import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/model/DialoutServerModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class ServerStatusViewModel extends AsyncNotifier<List<DialoutServerModel>> {
  @override
  Future<List<DialoutServerModel>> build() async {
    final repo = ref.read(repositoryProvider);
    // Re-fetches whenever the product dropdown changes.
    final product = ref.watch(selectedServerProductProvider);
    return repo.getDialoutServers(gradit: product == graditProduct);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Updates one flag on the server. Returns an error message, or null on success.
  Future<String?> updateFlag(
      DialoutServerModel server,
      String flagKey,
      bool value,
      ) async {
    final schoolUserId = ref.read(loginProvider).value?.schoolUserId ?? "";
    if (schoolUserId.isEmpty) {
      return "User details not found. Please login again.";
    }

    try {
      final repo = ref.read(repositoryProvider);
      final flags = await repo.updateDialoutServerFlag(
        serverId: server.id,
        createdBy: int.tryParse(schoolUserId) ?? schoolUserId,
        flagKey: flagKey,
        value: value,
        gradit: ref.read(selectedServerProductProvider) == graditProduct,
      );

      final current = state.value ?? [];
      state = AsyncData([
        for (final s in current) s.id == server.id ? s.withFlags(flags) : s,
      ]);
      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}

final serverStatusViewModelProvider =
AsyncNotifierProvider<ServerStatusViewModel, List<DialoutServerModel>>(
  ServerStatusViewModel.new,
);

const schoolChimesProduct = "School Chimes";
const graditProduct = "GRADit";
const serverProducts = [schoolChimesProduct, graditProduct];

final selectedServerProductProvider =
StateProvider<String>((ref) => serverProducts.first);
