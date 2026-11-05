import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Loads the OpenFreeMap "bright" vector style once per app session.
/// If it fails (offline, server down), the next call tries again.
class MapStyleService {
  static const styleUrl = 'https://tiles.openfreemap.org/styles/bright';

  static Future<Style>? _style;

  static Future<Style> bright() {
    return _style ??= StyleReader(uri: styleUrl).read().catchError((e) {
      _style = null; // allow a retry next time
      throw e;
    });
  }
}
