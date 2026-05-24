import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class TroubleshootingMeasurement {
  const TroubleshootingMeasurement({
    required this.point,
    required this.expected,
    required this.condition,
  });

  final String point;
  final String expected;
  final String condition;

  factory TroubleshootingMeasurement.fromJson(Map<String, dynamic> json) {
    return TroubleshootingMeasurement(
      point: (json['point'] ?? '') as String,
      expected: (json['expected'] ?? '') as String,
      condition: (json['condition'] ?? '') as String,
    );
  }
}

class TroubleshootingStep {
  const TroubleshootingStep({
    required this.id,
    required this.title,
    required this.node,
    required this.symptom,
    required this.checklist,
    required this.possibleCauses,
    required this.firstChecks,
    required this.diagnosticMistakes,
    required this.realCases,
    required this.measurements,
    required this.recommendations,
    required this.notes,
    required this.pdfAsset,
    required this.pages,
    required this.todo,
  });

  final String id;
  final String title;
  final String node;
  final String symptom;
  final List<String> checklist;
  final List<String> possibleCauses;
  final List<String> firstChecks;
  final List<String> diagnosticMistakes;
  final List<String> realCases;
  final List<TroubleshootingMeasurement> measurements;
  final List<String> recommendations;
  final List<String> notes;
  final String pdfAsset;
  final List<int> pages;
  final String todo;

  factory TroubleshootingStep.fromJson(Map<String, dynamic> json) {
    final pdf = (json['pdf'] as Map<String, dynamic>?) ?? const {};
    final checklistJson = (json['checklist'] as List<dynamic>? ?? const []);
    final measurementsJson =
        (json['measurements'] as List<dynamic>? ?? const []);
    final pagesJson = (pdf['pages'] as List<dynamic>? ?? const []);
    final possibleCausesJson =
        (json['possible_causes'] as List<dynamic>? ?? const []);
    final firstChecksJson = (json['first_checks'] as List<dynamic>? ?? const []);
    final diagnosticMistakesJson =
        (json['diagnostic_mistakes'] as List<dynamic>? ?? const []);
    final realCasesJson = (json['real_cases'] as List<dynamic>? ?? const []);
    final recommendationsJson =
        (json['recommendations'] as List<dynamic>? ?? const []);
    final notesJson = (json['notes'] as List<dynamic>? ?? const []);

    return TroubleshootingStep(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      node: (json['node'] ?? '') as String,
      symptom: (json['symptom'] ?? '') as String,
      checklist: checklistJson
          .map((item) => ((item as Map<String, dynamic>)['text'] ?? '') as String)
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      possibleCauses: possibleCausesJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      firstChecks: firstChecksJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      diagnosticMistakes: diagnosticMistakesJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      realCases: realCasesJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      measurements: measurementsJson
          .map((item) => TroubleshootingMeasurement.fromJson(
              item as Map<String, dynamic>))
          .toList(growable: false),
      recommendations: recommendationsJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      notes: notesJson
          .map((item) => item.toString())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      pdfAsset: (pdf['asset'] ?? '') as String,
      pages: pagesJson
          .map((item) => item is int ? item : int.tryParse(item.toString()) ?? 0)
          .where((page) => page > 0)
          .toList(growable: false),
      todo: (json['todo'] ?? '') as String,
    );
  }
}

class TroubleshootingModel {
  const TroubleshootingModel({
    required this.id,
    required this.displayName,
    required this.steps,
  });

  final String id;
  final String displayName;
  final List<TroubleshootingStep> steps;

  List<String> get nodes {
    final seen = <String>{};
    final ordered = <String>[];
    for (final step in steps) {
      if (seen.add(step.node)) {
        ordered.add(step.node);
      }
    }
    const preferredOrder = [
      'Электрика',
      'Гидравлика',
      'Двигатель',
      'CAN шина',
      'Управление',
      'Практика',
    ];

    ordered.sort((left, right) {
      final leftIndex = preferredOrder.indexOf(left);
      final rightIndex = preferredOrder.indexOf(right);
      final normalizedLeft = leftIndex == -1 ? preferredOrder.length : leftIndex;
      final normalizedRight =
          rightIndex == -1 ? preferredOrder.length : rightIndex;
      if (normalizedLeft != normalizedRight) {
        return normalizedLeft.compareTo(normalizedRight);
      }
      return left.compareTo(right);
    });

    return ordered;
  }

  List<TroubleshootingStep> stepsForNode(String node) {
    return steps.where((step) => step.node == node).toList(growable: false);
  }

  TroubleshootingStep? stepById(String stepId) {
    for (final step in steps) {
      if (step.id == stepId) {
        return step;
      }
    }
    return null;
  }
}

class TroubleshootingCatalog {
  const TroubleshootingCatalog({
    required this.schemaVersion,
    required this.models,
  });

  final String schemaVersion;
  final List<TroubleshootingModel> models;

  TroubleshootingModel? findByDisplayName(String displayName) {
    for (final model in models) {
      if (model.displayName == displayName) {
        return model;
      }
    }
    return null;
  }

  TroubleshootingModel? findById(String modelId) {
    for (final model in models) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }
}

class TroubleshootingRepository {
  TroubleshootingRepository._();

  static final TroubleshootingRepository instance =
      TroubleshootingRepository._();

  Future<TroubleshootingCatalog>? _catalogFuture;

  Future<TroubleshootingCatalog> loadCatalog() {
    return _catalogFuture ??= _readCatalog();
  }

  Future<TroubleshootingCatalog> _readCatalog() async {
    final modelsRaw = await rootBundle.loadString('assets/index/models.json');
    final troubleshootingRaw =
        await rootBundle.loadString('assets/index/troubleshooting.json');

    final modelNames =
        (jsonDecode(modelsRaw) as List<dynamic>).cast<String>().toList();
    final troubleshooting =
        jsonDecode(troubleshootingRaw) as Map<String, dynamic>;
    final modelEntries =
        (troubleshooting['models'] as List<dynamic>? ?? const []);

    final displayNamesById = _buildDisplayNames(modelNames);
    final models = modelEntries.map((entry) {
      final json = entry as Map<String, dynamic>;
      final id = (json['model_id'] ?? '') as String;
      final stepsJson = (json['steps'] as List<dynamic>? ?? const []);
      return TroubleshootingModel(
        id: id,
        displayName: displayNamesById[id] ?? id.toUpperCase(),
        steps: stepsJson
            .map((step) =>
                TroubleshootingStep.fromJson(step as Map<String, dynamic>))
            .toList(growable: false),
      );
    }).toList(growable: false);

    return TroubleshootingCatalog(
      schemaVersion: (troubleshooting['schema_version'] ?? 'unknown') as String,
      models: models,
    );
  }

  Map<String, String> _buildDisplayNames(List<String> displayNames) {
    final ids = ['dnk10', 'dnk14', 'dnk17', 'shs30'];
    final result = <String, String>{};
    for (var index = 0; index < displayNames.length && index < ids.length; index++) {
      result[ids[index]] = displayNames[index];
    }
    return result;
  }
}
