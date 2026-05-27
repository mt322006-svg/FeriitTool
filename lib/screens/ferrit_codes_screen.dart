import 'package:flutter/material.dart';

import '../data/ferrit_codes_repository.dart';

class FerritCodesScreen extends StatefulWidget {
  const FerritCodesScreen({super.key});

  @override
  State<FerritCodesScreen> createState() => _FerritCodesScreenState();
}

class _FerritCodesScreenState extends State<FerritCodesScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Коды Ferrit')),
      body: FutureBuilder<FerritCodesCatalog>(
        future: FerritCodesRepository.instance.loadCatalog(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Не удалось загрузить коды Ferrit.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final catalog = snapshot.data!;
          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: _search,
            builder: (context, value, _) {
              final query = value.text.trim();
              final filtered = catalog.items.where((e) => e.matches(query)).toList();
              filtered.sort((a, b) {
                if (query.isNotEmpty) {
                  final qa = a.code.toString() == query ? 0 : 1;
                  final qb = b.code.toString() == query ? 0 : 1;
                  if (qa != qb) {
                    return qa.compareTo(qb);
                  }
                }
                return a.code.compareTo(b.code);
              });

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _search,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Например: 21',
                        labelText: 'Поиск по номеру или описанию',
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _search.clear,
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Найдено: ${filtered.length} из ${catalog.items.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _FerritCodeCard(item: item);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FerritCodeCard extends StatelessWidget {
  final FerritCode item;

  const _FerritCodeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Код ${item.code}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(item.description),
            if (item.actionNew.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Действие: ${item.actionNew}'),
            ],
            if (item.activationConditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Условия: ${item.activationConditions}'),
            ],
            if (item.programCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Program code: ${item.programCode}'),
            ],
          ],
        ),
      ),
    );
  }
}
