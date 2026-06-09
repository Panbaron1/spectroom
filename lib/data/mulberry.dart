import 'package:flutter/services.dart';

/// Lists the Mulberry symbols actually bundled under assets/pictograms/.
/// Reads the asset manifest at runtime so the builder picker stays in sync
/// with whatever SVGs are shipped — no hardcoded index to maintain.
Future<List<String>> bundledMulberrySymbols() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest
      .listAssets()
      .where((a) =>
          a.startsWith('assets/pictograms/') && a.endsWith('.svg'))
      .map((a) => a.split('/').last.replaceAll('.svg', ''))
      .toList()
    ..sort();
}
