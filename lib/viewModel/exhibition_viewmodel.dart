import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ExhibitionModel.dart';
import '../core/exhibition/demo_templates.dart';
import '../provider/app_providers.dart';
import '../repository/exhibition_repository.dart';

final exhibitionRepositoryProvider = Provider<ExhibitionRepository>(
  (ref) => ExhibitionRepository(ref.read(dioProvider)),
);

/// All exhibitions, newest first. Search and the status chips filter this
/// list on the device so they respond instantly at a busy stall.
/// No automatic retry: at a stall with patchy Wi-Fi the user should see
/// "Couldn't load … Retry" instead of an endless skeleton.
Duration? _noRetry(int retryCount, Object error) => null;

final exhibitionListProvider = FutureProvider.autoDispose<List<Exhibition>>(retry: _noRetry, (
  ref,
) async {
  final items = await ref.read(exhibitionRepositoryProvider).fetchExhibitions();
  final sorted = [...items]
    ..sort((a, b) {
      final da = a.createdAt ?? a.startDate ?? DateTime(1970);
      final db = b.createdAt ?? b.startDate ?? DateTime(1970);
      return db.compareTo(da);
    });
  return sorted;
});

final exhibitionDetailProvider = FutureProvider.autoDispose.family<Exhibition, String>(
  retry: _noRetry,
  (ref, id) {
    return ref.read(exhibitionRepositoryProvider).fetchExhibition(id);
  },
);

final exhibitionDemosProvider = FutureProvider.autoDispose.family<List<ExhibitionDemo>, String>(
  retry: _noRetry,
  (ref, id) async {
    final items = await ref.read(exhibitionRepositoryProvider).fetchDemos(id);
    return [...items]
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
  },
);

final exhibitionLeadsProvider = FutureProvider.autoDispose.family<List<ExhibitionLead>, String>(
  retry: _noRetry,
  (ref, id) async {
    final items = await ref.read(exhibitionRepositoryProvider).fetchLeads(id);
    return [...items]
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
  },
);

/// Refreshes everything shown on an exhibition's screen and the list counts.
void refreshExhibition(WidgetRef ref, String id) {
  ref.invalidate(exhibitionDetailProvider(id));
  ref.invalidate(exhibitionDemosProvider(id));
  ref.invalidate(exhibitionLeadsProvider(id));
  ref.invalidate(exhibitionListProvider);
}

/// Voice templates for Give Demo, loaded from the API (not bundled in the
/// app). Kept alive so demo rows can name the voice without refetching.
final exhibitionTemplatesProvider = FutureProvider<List<DemoTemplate>>(
  retry: _noRetry,
  (ref) async {
    // Hardcoded templates for now; API templates are appended when the
    // endpoint is available (its failure is ignored).
    List<DemoTemplate> fromApi = const [];
    try {
      fromApi = await ref.read(exhibitionRepositoryProvider).fetchTemplates();
    } catch (_) {}
    final ids = exhibitionDemoTemplates.map((t) => t.id).toSet();
    return [
      ...exhibitionDemoTemplates,
      ...fromApi.where((t) => !ids.contains(t.id)),
    ];
  },
);
