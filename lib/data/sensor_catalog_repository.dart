import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class SensorCatalogItem {
  const SensorCatalogItem({
    required this.title,
    required this.group,
    required this.itemId,
  });

  final String title;
  final int group;
  final int itemId;

  factory SensorCatalogItem.fromJson(Map<String, dynamic> json) {
    return SensorCatalogItem(
      title: (json['title'] ?? '') as String,
      group: (json['group'] ?? 0) as int,
      itemId: (json['item_id'] ?? 0) as int,
    );
  }
}

class SensorCatalogCategory {
  const SensorCatalogCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final String type;
  final List<SensorCatalogItem> items;

  factory SensorCatalogCategory.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? const []);
    return SensorCatalogCategory(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      items: itemsJson
          .map((item) => SensorCatalogItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class SensorCatalog {
  const SensorCatalog({
    required this.source,
    required this.categories,
  });

  final String source;
  final List<SensorCatalogCategory> categories;

  int get totalItems => categories.fold<int>(
        0,
        (sum, category) => sum + category.items.length,
      );
}

class SensorCatalogRepository {
  SensorCatalogRepository._();

  static final SensorCatalogRepository instance = SensorCatalogRepository._();

  Future<SensorCatalog>? _catalogFuture;

  Future<SensorCatalog> loadCatalog() {
    return _catalogFuture ??= _readCatalog();
  }

  Future<SensorCatalog> _readCatalog() async {
    final raw = await rootBundle.loadString('assets/index/sensors_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final categoriesJson = (json['categories'] as List<dynamic>? ?? const []);

    return SensorCatalog(
      source: (json['source'] ?? '') as String,
      categories: categoriesJson
          .map((entry) =>
              SensorCatalogCategory.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
