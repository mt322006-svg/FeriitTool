import 'package:flutter/material.dart';

import '../data/cummins_codes_repository.dart';

class EngineCodesScreen extends StatefulWidget {
  final String modelName;

  const EngineCodesScreen({
    super.key,
    required this.modelName,
  });

  @override
  State<EngineCodesScreen> createState() => _EngineCodesScreenState();
}

class _EngineCodesScreenState extends State<EngineCodesScreen> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Коды двигателя')),
      body: FutureBuilder<CumminsCodesCatalog>(
        future: CumminsCodesRepository.instance.loadCatalog(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Не удалось загрузить базу кодов двигателя.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final catalog = snapshot.data!;
          final filtered = catalog.codes
              .where((code) => code.matches(_query))
              .toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _CodesHeader(
                  modelName: widget.modelName,
                  engineName: catalog.engine,
                  totalCount: catalog.codes.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SearchPanel(
                  controller: _searchController,
                  query: _query,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _HintChip(label: 'Поиск по fault code'),
                    SizedBox(width: 8),
                    _HintChip(label: 'SPN / FMI'),
                    SizedBox(width: 8),
                    _HintChip(label: 'Описание'),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('По этому запросу ничего не найдено.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _CodeCard(code: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CodesHeader extends StatelessWidget {
  final String modelName;
  final String engineName;
  final int totalCount;

  const _CodesHeader({
    required this.modelName,
    required this.engineName,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E343D), Color(0xFF1F242B)],
        ),
        border: Border.all(color: const Color(0x44FF8A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cummins для $modelName',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '$engineName · $totalCount кодов в локальной базе',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Подходит для серий ПДМ-14 и ПДМ-17. На ПДМ-10 этот раздел не используется.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchPanel({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Искать по коду, SPN, FMI или описанию',
          prefixIcon: const Icon(Icons.manage_search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;

  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final CumminsCode code;

  const _CodeCard({required this.code});

  Color _lampColor() {
    final lamp = code.lamp.toLowerCase();
    if (lamp.contains('red')) {
      return const Color(0xFFE35D5D);
    }
    if (lamp.contains('yellow')) {
      return const Color(0xFFFFC857);
    }
    return const Color(0xFF91A0B4);
  }

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatBadge(label: 'Fault', value: code.faultCode.toString()),
              _StatBadge(label: 'SPN', value: code.spn.toString()),
              _StatBadge(label: 'FMI', value: code.fmi.toString()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _lampColor().withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _lampColor().withValues(alpha: 0.5)),
                ),
                child: Text(
                  code.lamp.replaceAll('(', '').replaceAll(')', ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: _lampColor()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            code.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x14FF8A3D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x44FF8A3D)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
