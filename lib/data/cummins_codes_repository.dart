import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class CumminsCode {
  const CumminsCode({
    required this.faultCode,
    required this.spn,
    required this.fmi,
    required this.description,
    required this.descriptionRu,
    required this.lamp,
    required this.modelFlag,
  });

  final int faultCode;
  final int spn;
  final int fmi;
  final String description;
  final String descriptionRu;
  final String lamp;
  final String modelFlag;

  factory CumminsCode.fromJson(Map<String, dynamic> json) {
    int parseInt(Object? value) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CumminsCode(
      faultCode: parseInt(json['fault_code']),
      spn: parseInt(json['spn']),
      fmi: parseInt(json['fmi']),
      description: (json['description'] ?? '') as String,
      descriptionRu: (json['description_ru'] ?? json['description'] ?? '') as String,
      lamp: (json['lamp'] ?? '') as String,
      modelFlag: (json['model_flag'] ?? '') as String,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return faultCode.toString().contains(normalized) ||
        spn.toString().contains(normalized) ||
        fmi.toString().contains(normalized) ||
        descriptionRu.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        lamp.toLowerCase().contains(normalized);
  }
}

class CumminsCodesCatalog {
  const CumminsCodesCatalog({
    required this.schemaVersion,
    required this.engine,
    required this.codes,
  });

  final String schemaVersion;
  final String engine;
  final List<CumminsCode> codes;
}

class CumminsCodesRepository {
  CumminsCodesRepository._();

  static final CumminsCodesRepository instance = CumminsCodesRepository._();

  Future<CumminsCodesCatalog>? _catalogFuture;

  Future<CumminsCodesCatalog> loadCatalog() {
    return _catalogFuture ??= _readCatalog();
  }

  Future<CumminsCodesCatalog> _readCatalog() async {
    final raw = await rootBundle.loadString('assets/index/cummins_codes.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final codesJson = (decoded['codes'] as List<dynamic>? ?? const []);

    return CumminsCodesCatalog(
      schemaVersion: (decoded['schema_version'] ?? 'unknown') as String,
      engine: (decoded['engine'] ?? 'Cummins') as String,
      codes: codesJson
          .map((item) => CumminsCode.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
