import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class FerritCode {
  const FerritCode({
    required this.code,
    required this.description,
    required this.actionNew,
    required this.action,
    required this.activationConditions,
    required this.programCode,
    required this.note,
    required this.applicability,
  });

  final int code;
  final String description;
  final String actionNew;
  final String action;
  final String activationConditions;
  final String programCode;
  final String note;
  final Map<String, String> applicability;

  factory FerritCode.fromJson(Map<String, dynamic> json) {
    int parseInt(Object? value) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final appRaw = (json['applicability'] as Map<String, dynamic>? ?? const {});
    return FerritCode(
      code: parseInt(json['code']),
      description: (json['description'] ?? '') as String,
      actionNew: (json['action_new'] ?? '') as String,
      action: (json['action'] ?? '') as String,
      activationConditions: (json['activation_conditions'] ?? '') as String,
      programCode: (json['program_code'] ?? '') as String,
      note: (json['note'] ?? '') as String,
      applicability: appRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return code.toString().contains(q) ||
        description.toLowerCase().contains(q) ||
        actionNew.toLowerCase().contains(q) ||
        action.toLowerCase().contains(q) ||
        activationConditions.toLowerCase().contains(q) ||
        programCode.toLowerCase().contains(q) ||
        note.toLowerCase().contains(q);
  }
}

class FerritCodesCatalog {
  const FerritCodesCatalog({
    required this.title,
    required this.items,
  });

  final String title;
  final List<FerritCode> items;
}

class FerritCodesRepository {
  FerritCodesRepository._();

  static final FerritCodesRepository instance = FerritCodesRepository._();

  Future<FerritCodesCatalog>? _future;

  Future<FerritCodesCatalog> loadCatalog() {
    return _future ??= _read();
  }

  Future<FerritCodesCatalog> _read() async {
    final raw = await rootBundle.loadString('assets/index/ferrit_codes.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final itemsJson = (decoded['items'] as List<dynamic>? ?? const []);
    return FerritCodesCatalog(
      title: (decoded['title'] ?? 'Коды Ferrit') as String,
      items: itemsJson
          .map((e) => FerritCode.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

