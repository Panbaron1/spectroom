import 'package:flutter/services.dart';

/// Lists the kawaii PNG icons bundled under assets/icons/.
/// Reads the asset manifest at runtime — stays in sync with whatever is shipped.
Future<List<String>> bundledAssetIcons() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest
      .listAssets()
      .where((a) => a.startsWith('assets/icons/') && a.endsWith('.png'))
      .map((a) => a.split('/').last.replaceAll('.png', ''))
      .toList()
    ..sort();
}
