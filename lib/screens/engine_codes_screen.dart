import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_session_store.dart';
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
  late final TextEditingController _faultController;
  late final TextEditingController _spnController;
  late final TextEditingController _fmiController;
  late final TextEditingController _textController;

  String _faultQuery = '';
  String _spnQuery = '';
  String _fmiQuery = '';
  String _textQuery = '';

  @override
  void initState() {
    super.initState();
    _faultController = TextEditingController();
    _spnController = TextEditingController();
    _fmiController = TextEditingController();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _faultController.dispose();
    _spnController.dispose();
    _fmiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Коды двигателя')),
      body: AnimatedBuilder(
        animation: AppSessionStore.instance,
        builder: (context, _) => FutureBuilder<CumminsCodesCatalog>(
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
            final filtered =
                catalog.codes.where(_matchesFilters).toList(growable: false);
            final summaryCode = _resolveSummaryCode(filtered);
            final favoriteCodes = AppSessionStore.instance.favoriteFaultCodes
                .map((faultCode) =>
                    catalog.codes.where((code) => code.faultCode == faultCode))
                .expand((codes) => codes)
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _CodesHeader(
                  modelName: widget.modelName,
                  engineName: catalog.engine,
                  totalCount: catalog.codes.length,
                ),
                const SizedBox(height: 12),
                _SearchPanel(
                  faultController: _faultController,
                  spnController: _spnController,
                  fmiController: _fmiController,
                  textController: _textController,
                  faultQuery: _faultQuery,
                  spnQuery: _spnQuery,
                  fmiQuery: _fmiQuery,
                  textQuery: _textQuery,
                  onFaultChanged: (value) =>
                      setState(() => _faultQuery = value.trim()),
                  onSpnChanged: (value) =>
                      setState(() => _spnQuery = value.trim()),
                  onFmiChanged: (value) =>
                      setState(() => _fmiQuery = value.trim()),
                  onTextChanged: (value) =>
                      setState(() => _textQuery = value.trim()),
                  onClearAll: _clearFilters,
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HintChip(label: 'Fault отдельно'),
                    _HintChip(label: 'SPN отдельно'),
                    _HintChip(label: 'FMI отдельно'),
                    _HintChip(label: 'RU / EN описание'),
                  ],
                ),
                if (summaryCode != null) ...[
                  const SizedBox(height: 12),
                  _SummaryCard(
                    code: summaryCode,
                    firstChecks: _buildFirstChecks(summaryCode),
                    isFavorite: AppSessionStore.instance.isFavoriteFaultCode(
                      summaryCode.faultCode,
                    ),
                    onToggleFavorite: () => AppSessionStore.instance
                        .toggleFavoriteFaultCode(summaryCode.faultCode),
                    onCopy: () => _copyCodeSummary(summaryCode),
                  ),
                ],
                if (favoriteCodes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FavoriteCodesSection(
                    codes: favoriteCodes,
                    onTapCode: (code) => _applyFaultFilter(code.faultCode),
                    isFavorite: AppSessionStore.instance.isFavoriteFaultCode,
                    onToggleFavorite:
                        AppSessionStore.instance.toggleFavoriteFaultCode,
                  ),
                ],
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text('По этому запросу ничего не найдено.'),
                    ),
                  )
                else
                  ...filtered.map(
                    (code) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CodeCard(
                        code: code,
                        isFavorite:
                            AppSessionStore.instance.isFavoriteFaultCode(
                          code.faultCode,
                        ),
                        onToggleFavorite: () => AppSessionStore.instance
                            .toggleFavoriteFaultCode(code.faultCode),
                        onCopy: () => _copyCodeSummary(code),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilters(CumminsCode code) {
    if (_faultQuery.isNotEmpty &&
        !code.faultCode.toString().contains(_faultQuery)) {
      return false;
    }
    if (_spnQuery.isNotEmpty && !code.spn.toString().contains(_spnQuery)) {
      return false;
    }
    if (_fmiQuery.isNotEmpty && !code.fmi.toString().contains(_fmiQuery)) {
      return false;
    }

    final normalizedText = _textQuery.toLowerCase();
    if (normalizedText.isNotEmpty &&
        !code.descriptionRu.toLowerCase().contains(normalizedText) &&
        !code.description.toLowerCase().contains(normalizedText) &&
        !code.lamp.toLowerCase().contains(normalizedText)) {
      return false;
    }

    return true;
  }

  void _clearFilters() {
    _faultController.clear();
    _spnController.clear();
    _fmiController.clear();
    _textController.clear();
    setState(() {
      _faultQuery = '';
      _spnQuery = '';
      _fmiQuery = '';
      _textQuery = '';
    });
  }

  CumminsCode? _resolveSummaryCode(List<CumminsCode> filtered) {
    if (filtered.isEmpty) {
      return null;
    }

    final exactFault = int.tryParse(_faultQuery);
    if (exactFault != null) {
      for (final code in filtered) {
        if (code.faultCode == exactFault) {
          return code;
        }
      }
    }

    final exactSpn = int.tryParse(_spnQuery);
    final exactFmi = int.tryParse(_fmiQuery);
    if (exactSpn != null || exactFmi != null) {
      final exactMatches = filtered.where((code) {
        final spnMatches = exactSpn == null || code.spn == exactSpn;
        final fmiMatches = exactFmi == null || code.fmi == exactFmi;
        return spnMatches && fmiMatches;
      }).toList(growable: false);
      if (exactMatches.length == 1) {
        return exactMatches.first;
      }
    }

    return filtered.length == 1 ? filtered.first : null;
  }

  List<String> _buildFirstChecks(CumminsCode code) {
    final ru = code.descriptionRu.toLowerCase();
    final en = code.description.toLowerCase();

    if (ru.contains('j1939') ||
        ru.contains('can') ||
        en.contains('j1939') ||
        en.contains('datalink') ||
        code.spn == 639) {
      return const [
        'Проверить питание и массы узлов шины под нагрузкой.',
        'Проверить напряжения CAN_H / CAN_L относительно массы.',
        'Проверить сопротивление между CAN_H и CAN_L на отключённой машине: ориентир около 120-130 Ом для этой техники.',
      ];
    }
    if (ru.contains('датчика') ||
        ru.contains('sensor') ||
        ru.contains('опорного напряжения') ||
        en.contains('sensor')) {
      return const [
        'Проверить питание датчика и опорное напряжение.',
        'Проверить массу датчика под нагрузкой.',
        'Проверить разъём и жгут на обрыв, окисление и замыкание на плюс/массу.',
      ];
    }
    if (ru.contains('питания') ||
        ru.contains('напряжение') ||
        ru.contains('аккумулятор') ||
        en.contains('voltage') ||
        en.contains('power supply')) {
      return const [
        'Проверить аккумуляторное питание и ignition под нагрузкой.',
        'Проверить массы ECU и силовые массы двигателя.',
        'Проверить просадку напряжения в момент запуска или появления кода.',
      ];
    }
    if (ru.contains('форсун') || en.contains('injector')) {
      return const [
        'Проверить разъём форсунки и целостность жгута до ECU.',
        'Проверить цепь на обрыв и замыкание на массу/плюс.',
        'Не менять форсунку до проверки проводки и драйвера ECU.',
      ];
    }
    if (ru.contains('давления масла') ||
        ru.contains('охлаждающей жидкости') ||
        ru.contains('температур') ||
        en.contains('oil pressure') ||
        en.contains('coolant') ||
        en.contains('temperature')) {
      return const [
        'Проверить сам датчик и его питание/массу.',
        'Проверить разъём, жгут и отсутствие замыкания на плюс/массу.',
        'Сопоставить код с реальным параметром, а не только со сканером.',
      ];
    }

    return const [
      'Проверить питание и массы связанного узла под нагрузкой.',
      'Проверить разъёмы и жгут на обрыв, окисление и натяжение.',
      'Сначала подтвердить цепь измерением, а потом менять узел.',
    ];
  }

  Future<void> _copyCodeSummary(CumminsCode code) async {
    final summary =
        'Fault ${code.faultCode} | SPN ${code.spn} | FMI ${code.fmi}\n${code.descriptionRu}\n${code.description}';
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Код скопирован в буфер')),
    );
  }

  void _applyFaultFilter(int faultCode) {
    _faultController.text = faultCode.toString();
    setState(() {
      _faultQuery = faultCode.toString();
    });
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
  final TextEditingController faultController;
  final TextEditingController spnController;
  final TextEditingController fmiController;
  final TextEditingController textController;
  final String faultQuery;
  final String spnQuery;
  final String fmiQuery;
  final String textQuery;
  final ValueChanged<String> onFaultChanged;
  final ValueChanged<String> onSpnChanged;
  final ValueChanged<String> onFmiChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onClearAll;

  const _SearchPanel({
    required this.faultController,
    required this.spnController,
    required this.fmiController,
    required this.textController,
    required this.faultQuery,
    required this.spnQuery,
    required this.fmiQuery,
    required this.textQuery,
    required this.onFaultChanged,
    required this.onSpnChanged,
    required this.onFmiChanged,
    required this.onTextChanged,
    required this.onClearAll,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactSearchField(
                  controller: faultController,
                  label: 'Fault',
                  onChanged: onFaultChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactSearchField(
                  controller: spnController,
                  label: 'SPN',
                  onChanged: onSpnChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactSearchField(
                  controller: fmiController,
                  label: 'FMI',
                  onChanged: onFmiChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: textController,
            onChanged: onTextChanged,
            decoration: InputDecoration(
              hintText: 'Поиск по русскому или английскому описанию',
              prefixIcon: const Icon(Icons.manage_search),
              suffixIcon: (faultQuery + spnQuery + fmiQuery + textQuery).isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _CompactSearchField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
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
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;

  const _CodeCard({
    required this.code,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onCopy,
  });

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

  String _lampLabel() {
    final lamp = code.lamp.toLowerCase();
    if (lamp.contains('red')) {
      return 'Красная';
    }
    if (lamp.contains('yellow')) {
      return 'Жёлтая';
    }
    return code.lamp.replaceAll('(', '').replaceAll(')', '');
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _lampColor().withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: _lampColor().withValues(alpha: 0.5)),
                ),
                child: Text(
                  _lampLabel(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: _lampColor()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
              ),
              IconButton(
                tooltip: 'Копировать код',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_all_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            code.descriptionRu,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            code.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CumminsCode code;
  final List<String> firstChecks;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;

  const _SummaryCard({
    required this.code,
    required this.firstChecks,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C2B17), Color(0xFF2C313A)],
        ),
        border: Border.all(color: const Color(0x88FF7A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Точное совпадение: Fault ${code.faultCode}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
              ),
              IconButton(
                tooltip: 'Копировать код',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_all_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatBadge(label: 'Fault', value: code.faultCode.toString()),
              _StatBadge(label: 'SPN', value: code.spn.toString()),
              _StatBadge(label: 'FMI', value: code.fmi.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Text(code.descriptionRu,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(code.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            'Что смотреть первым делом',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...firstChecks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rule_folder_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(check)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCodesSection extends StatelessWidget {
  final List<CumminsCode> codes;
  final ValueChanged<CumminsCode> onTapCode;
  final bool Function(int faultCode) isFavorite;
  final ValueChanged<int> onToggleFavorite;

  const _FavoriteCodesSection({
    required this.codes,
    required this.onTapCode,
    required this.isFavorite,
    required this.onToggleFavorite,
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
          Text('Избранные коды', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: codes
                .map(
                  (code) => InputChip(
                    label: Text('Fault ${code.faultCode}'),
                    selected: isFavorite(code.faultCode),
                    onPressed: () => onTapCode(code),
                    onDeleted: () => onToggleFavorite(code.faultCode),
                  ),
                )
                .toList(growable: false),
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
