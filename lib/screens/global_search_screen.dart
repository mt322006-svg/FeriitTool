import 'package:flutter/material.dart';

import '../data/app_session_store.dart';
import '../data/cummins_codes_repository.dart';
import '../data/sensor_catalog_repository.dart';
import '../data/troubleshooting_repository.dart';
import 'engine_codes_screen.dart';
import 'sensors_screen.dart';
import 'symptom_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Глобальный поиск')),
      body: FutureBuilder<_SearchData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Не удалось загрузить данные поиска.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final symptomResults = _buildSymptomResults(data.catalog, _query);
          final sensorResults = _buildSensorResults(data.sensors, _query);
          final codeResults = _buildCodeResults(data.codes, _query);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Симптом, fault code, SPN, датчик...',
                    prefixIcon: const Icon(Icons.manage_search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _SearchSection<SearchSymptomResult>(
                      title: 'Симптомы и troubleshooting',
                      results: symptomResults,
                      emptyText: 'По симптомам ничего не найдено.',
                      itemBuilder: (item) => _ResultTile(
                        icon: Icons.construction_outlined,
                        title: item.step.title,
                        subtitle:
                            '${item.model.displayName} · ${item.step.node}${item.step.symptom.isNotEmpty ? "\n${item.step.symptom}" : ""}',
                        onTap: () {
                          final ref = SymptomRef(
                            modelId: item.model.id,
                            stepId: item.step.id,
                          );
                          AppSessionStore.instance.recordSymptomOpen(ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SymptomScreen(
                                modelId: item.model.id,
                                modelName: item.model.displayName,
                                step: item.step,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SearchSection<SearchCodeResult>(
                      title: 'Коды двигателя',
                      results: codeResults,
                      emptyText: 'По кодам двигателя ничего не найдено.',
                      itemBuilder: (item) => _ResultTile(
                        icon: Icons.memory_outlined,
                        title: 'Fault ${item.code.faultCode} · SPN ${item.code.spn} · FMI ${item.code.fmi}',
                        subtitle: item.code.description,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EngineCodesScreen(
                                modelName: 'ПДМ-14 / ПДМ-17',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SearchSection<SearchSensorResult>(
                      title: 'Датчики',
                      results: sensorResults,
                      emptyText: 'По датчикам ничего не найдено.',
                      itemBuilder: (item) => _ResultTile(
                        icon: Icons.thermostat_outlined,
                        title: item.item.title,
                        subtitle: '${item.category.title} · ${item.category.subtitle}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SensorDetailScreen(
                                category: item.category,
                                item: item.item,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_SearchData> _loadData() async {
    final catalog = await TroubleshootingRepository.instance.loadCatalog();
    final sensors = await SensorCatalogRepository.instance.loadCatalog();
    final codes = await CumminsCodesRepository.instance.loadCatalog();
    return _SearchData(catalog: catalog, sensors: sensors, codes: codes);
  }

  List<SearchSymptomResult> _buildSymptomResults(
    TroubleshootingCatalog catalog,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    final results = <SearchSymptomResult>[];
    for (final model in catalog.models) {
      for (final step in model.steps) {
        final haystack = [
          model.displayName,
          step.title,
          step.node,
          step.symptom,
          ...step.checklist,
          ...step.possibleCauses,
        ].join(' ').toLowerCase();
        if (normalized.isEmpty || haystack.contains(normalized)) {
          results.add(SearchSymptomResult(model: model, step: step));
        }
      }
    }
    return results.take(24).toList(growable: false);
  }

  List<SearchSensorResult> _buildSensorResults(
    SensorCatalog catalog,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    final results = <SearchSensorResult>[];
    for (final category in catalog.categories) {
      for (final item in category.items) {
        final haystack = '${category.title} ${category.subtitle} ${item.title}'.toLowerCase();
        if (normalized.isEmpty || haystack.contains(normalized)) {
          results.add(SearchSensorResult(category: category, item: item));
        }
      }
    }
    return results.take(24).toList(growable: false);
  }

  List<SearchCodeResult> _buildCodeResults(
    CumminsCodesCatalog catalog,
    String query,
  ) {
    return catalog.codes
        .where((code) => code.matches(query))
        .take(24)
        .map((code) => SearchCodeResult(code: code))
        .toList(growable: false);
  }
}

class _SearchData {
  const _SearchData({
    required this.catalog,
    required this.sensors,
    required this.codes,
  });

  final TroubleshootingCatalog catalog;
  final SensorCatalog sensors;
  final CumminsCodesCatalog codes;
}

class SearchSymptomResult {
  const SearchSymptomResult({
    required this.model,
    required this.step,
  });

  final TroubleshootingModel model;
  final TroubleshootingStep step;
}

class SearchSensorResult {
  const SearchSensorResult({
    required this.category,
    required this.item,
  });

  final SensorCatalogCategory category;
  final SensorCatalogItem item;
}

class SearchCodeResult {
  const SearchCodeResult({required this.code});

  final CumminsCode code;
}

class _SearchSection<T> extends StatelessWidget {
  final String title;
  final List<T> results;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  const _SearchSection({
    required this.title,
    required this.results,
    required this.emptyText,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (results.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...results.map(itemBuilder),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
