import 'package:flutter/material.dart';

import '../data/sensor_calculator_repository.dart';
import '../data/sensor_catalog_repository.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Датчики и калькуляторы')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<SensorCatalog>(
          future: SensorCatalogRepository.instance.loadCatalog(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Не удалось загрузить каталог датчиков.'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final catalog = snapshot.data!;
            return ListView(
              children: [
                _IntroCard(catalog: catalog),
                const SizedBox(height: 16),
                ...catalog.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryCard(category: category),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final SensorCatalog catalog;

  const _IntroCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF323844), Color(0xFF1F242B)],
        ),
        border: Border.all(color: const Color(0x44FF8A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Датчики и температура', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Импортировано из донорской базы: ${catalog.totalItems} позиций в ${catalog.categories.length} категориях.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Для RTD и NTC уже доступен практический расчёт сопротивления и температуры прямо в карточке датчика.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SensorCatalogCategory category;

  const _CategoryCard({required this.category});

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
          Text(category.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(category.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.items
                .map(
                  (item) => ActionChip(
                    label: Text(item.title),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SensorDetailScreen(
                            category: category,
                            item: item,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class SensorDetailScreen extends StatefulWidget {
  final SensorCatalogCategory category;
  final SensorCatalogItem item;

  const SensorDetailScreen({
    super.key,
    required this.category,
    required this.item,
  });

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  late final TextEditingController _resistanceController;
  late final TextEditingController _temperatureController;
  String? _resultText;
  String? _errorText;

  SensorCalculatorSpec? get _calculator =>
      SensorCalculatorRepository.instance.forItem(widget.category, widget.item);

  @override
  void initState() {
    super.initState();
    _resistanceController = TextEditingController();
    _temperatureController = TextEditingController();
  }

  @override
  void dispose() {
    _resistanceController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  void _calculateFromResistance() {
    final calculator = _calculator;
    final resistance = double.tryParse(_resistanceController.text.replaceAll(',', '.'));
    if (calculator == null || resistance == null) {
      setState(() {
        _errorText = 'Введите корректное сопротивление.';
        _resultText = null;
      });
      return;
    }

    final result = calculator.resistanceToTemperature(resistance);
    if (result == null) {
      setState(() {
        _errorText =
            'Значение вне рабочего диапазона ${calculator.minTemperature}…${calculator.maxTemperature} °C.';
        _resultText = null;
      });
      return;
    }

    _temperatureController.text = result.value.toStringAsFixed(2);
    setState(() {
      _errorText = null;
      _resultText =
          '${resistance.toStringAsFixed(2)} Ω -> ${result.value.toStringAsFixed(2)} ${result.unit}';
    });
  }

  void _calculateFromTemperature() {
    final calculator = _calculator;
    final temperature =
        double.tryParse(_temperatureController.text.replaceAll(',', '.'));
    if (calculator == null || temperature == null) {
      setState(() {
        _errorText = 'Введите корректную температуру.';
        _resultText = null;
      });
      return;
    }

    final result = calculator.temperatureToResistance(temperature);
    if (result == null) {
      setState(() {
        _errorText =
            'Температура вне рабочего диапазона ${calculator.minTemperature}…${calculator.maxTemperature} °C.';
        _resultText = null;
      });
      return;
    }

    _resistanceController.text = result.value.toStringAsFixed(2);
    setState(() {
      _errorText = null;
      _resultText =
          '${temperature.toStringAsFixed(2)} °C -> ${result.value.toStringAsFixed(2)} ${result.unit}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final calculator = _calculator;

    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _DetailBlock(
              title: widget.item.title,
              lines: [
                'Категория: ${widget.category.title}',
                'Подтип: ${widget.category.type}',
                'Группа источника: ${widget.item.group}',
                'ID источника: ${widget.item.itemId}',
              ],
            ),
            const SizedBox(height: 12),
            if (calculator != null)
              _CalculatorCard(
                calculator: calculator,
                resistanceController: _resistanceController,
                temperatureController: _temperatureController,
                resultText: _resultText,
                errorText: _errorText,
                onCalculateFromResistance: _calculateFromResistance,
                onCalculateFromTemperature: _calculateFromTemperature,
              )
            else
              const _DetailBlock(
                title: 'Калькулятор',
                lines: [
                  'Для этой категории прямой расчёт по сопротивлению пока не включён.',
                  'RTD и NTC уже поддерживаются, термопары пойдут отдельным режимом по ЭДС и холодному спаю.',
                ],
              ),
            const SizedBox(height: 12),
            const _DetailBlock(
              title: 'Зачем это нам',
              lines: [
                'Это сервисный модуль для быстрых полевых расчётов по температурным датчикам.',
                'Можно вводить сопротивление и сразу получать ориентировочную температуру, либо наоборот.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final SensorCalculatorSpec calculator;
  final TextEditingController resistanceController;
  final TextEditingController temperatureController;
  final String? resultText;
  final String? errorText;
  final VoidCallback onCalculateFromResistance;
  final VoidCallback onCalculateFromTemperature;

  const _CalculatorCard({
    required this.calculator,
    required this.resistanceController,
    required this.temperatureController,
    required this.resultText,
    required this.errorText,
    required this.onCalculateFromResistance,
    required this.onCalculateFromTemperature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x44FF8A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Калькулятор', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Рабочий диапазон: ${calculator.minTemperature.toStringAsFixed(0)}…${calculator.maxTemperature.toStringAsFixed(0)} °C',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: resistanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Сопротивление, Ω',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCalculateFromResistance,
              icon: const Icon(Icons.functions),
              label: const Text('Рассчитать температуру'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Температура, °C',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCalculateFromTemperature,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Рассчитать сопротивление'),
            ),
          ),
          if (resultText != null) ...[
            const SizedBox(height: 14),
            _ResultBox(
              text: resultText!,
              color: const Color(0x14FF8A3D),
              borderColor: const Color(0x44FF8A3D),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 14),
            _ResultBox(
              text: errorText!,
              color: const Color(0x1AE35D5D),
              borderColor: const Color(0x55E35D5D),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;

  const _ResultBox({
    required this.text,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _DetailBlock({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
