import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/watch_face_model.dart';

class WatchFacesRepository {
  WatchFacesRepository({this.catalogAssetPath = _defaultCatalogPath});

  static const String _defaultCatalogPath =
      'assets/watch_faces/catalog/watch_faces.json';

  final String catalogAssetPath;

  List<WatchFace>? _cache;

  Future<List<WatchFace>> loadAll({bool forceReload = false}) async {
    if (_cache != null && !forceReload) return _cache!;

    final raw = await rootBundle.loadString(catalogAssetPath);
    final decoded = json.decode(raw);

    if (decoded is! Map<String, dynamic> || decoded['watchFaces'] is! List) {
      throw const FormatException(
        'Invalid catalog format: expected a "watchFaces" array.',
      );
    }

    final list = (decoded['watchFaces'] as List)
        .cast<Map<String, dynamic>>()
        .map(WatchFace.fromJson)
        .toList(growable: false);

    _cache = list;
    return list;
  }

  Future<List<WatchFace>> loadByPlatform(WatchPlatform platform) async {
    final all = await loadAll();
    return all.where((f) => f.platform == platform).toList(growable: false);
  }
}
