import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

class PdfAssetCache {
  PdfAssetCache._();

  static final PdfAssetCache instance = PdfAssetCache._();

  final Map<String, Future<Uint8List>> _entries = {};

  Future<Uint8List> load(String assetPath) {
    return _entries.putIfAbsent(assetPath, () async {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    });
  }
}
