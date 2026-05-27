import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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
                _QuickToolCard(
                  icon: Icons.calculate_outlined,
                  title: 'Обычный калькулятор',
                  subtitle:
                      'Быстрые базовые расчёты прямо в приложении ( +  -  ×  ÷ ).',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BasicCalculatorScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickToolCard(
                  icon: Icons.electrical_services_outlined,
                  title: 'Законы Ома',
                  subtitle: 'Расчёт U / I / R / P по известным значениям.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OhmsLawScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickToolCard(
                  icon: Icons.cable_outlined,
                  title: 'Сечение кабеля',
                  subtitle:
                      'Подбор сечения и оценка максимального тока для меди/алюминия.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CableSectionScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

class _QuickToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class BasicCalculatorScreen extends StatefulWidget {
  const BasicCalculatorScreen({super.key});

  @override
  State<BasicCalculatorScreen> createState() => _BasicCalculatorScreenState();
}

class _BasicCalculatorScreenState extends State<BasicCalculatorScreen> {
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  String _operation = '+';
  String? _result;
  String? _error;

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _calculate() {
    final a = double.tryParse(_aController.text.replaceAll(',', '.'));
    final b = double.tryParse(_bController.text.replaceAll(',', '.'));
    if (a == null || b == null) {
      setState(() {
        _error = 'Введите оба числа корректно.';
        _result = null;
      });
      return;
    }

    double value;
    switch (_operation) {
      case '-':
        value = a - b;
        break;
      case '×':
        value = a * b;
        break;
      case '÷':
        if (b == 0) {
          setState(() {
            _error = 'Деление на ноль недопустимо.';
            _result = null;
          });
          return;
        }
        value = a / b;
        break;
      case '+':
      default:
        value = a + b;
        break;
    }

    setState(() {
      _error = null;
      _result = value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    });
  }

  Future<void> _copyResult() async {
    if (_result == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _result!));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Результат скопирован')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обычный калькулятор')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _aController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Число A',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['+', '-', '×', '÷']
                  .map(
                    (op) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(op),
                          selected: _operation == op,
                          onSelected: (_) => setState(() => _operation = op),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Число B',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Посчитать'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x14FF8A3D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x44FF8A3D)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Результат: $_result',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Копировать',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: _copyResult,
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1AE35D5D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x55E35D5D)),
                ),
                child: Text(_error!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OhmsLawScreen extends StatefulWidget {
  const OhmsLawScreen({super.key});

  @override
  State<OhmsLawScreen> createState() => _OhmsLawScreenState();
}

class _OhmsLawScreenState extends State<OhmsLawScreen> {
  final _uCtrl = TextEditingController();
  final _iCtrl = TextEditingController();
  final _rCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _uCtrl.dispose();
    _iCtrl.dispose();
    _rCtrl.dispose();
    _pCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) {
      return null;
    }
    return double.tryParse(t);
  }

  String _fmt(double v) => v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

  void _solve() {
    final u = _parse(_uCtrl);
    final i = _parse(_iCtrl);
    final r = _parse(_rCtrl);
    final p = _parse(_pCtrl);
    final known = [u, i, r, p].whereType<double>().length;

    if (known < 2) {
      setState(() => _error = 'Нужно заполнить минимум 2 поля.');
      return;
    }

    double? uu = u;
    double? ii = i;
    double? rr = r;
    double? pp = p;

    if (uu != null && ii != null) {
      rr ??= ii == 0 ? null : uu / ii;
      pp ??= uu * ii;
    } else if (uu != null && rr != null) {
      ii ??= rr == 0 ? null : uu / rr;
      pp ??= uu * ii!;
    } else if (ii != null && rr != null) {
      uu ??= ii * rr;
      pp ??= uu * ii;
    } else if (uu != null && pp != null) {
      ii ??= uu == 0 ? null : pp / uu;
      rr ??= ii == null || ii == 0 ? null : uu / ii;
    } else if (ii != null && pp != null) {
      uu ??= ii == 0 ? null : pp / ii;
      rr ??= ii == 0 ? null : uu! / ii;
    } else if (rr != null && pp != null) {
      if (rr > 0) {
        ii ??= math.sqrt(pp / rr);
        uu ??= ii * rr;
      }
    }

    if (uu == null || ii == null || rr == null || pp == null) {
      setState(() => _error = 'Недостаточно данных или деление на ноль.');
      return;
    }

    _uCtrl.text = _fmt(uu);
    _iCtrl.text = _fmt(ii);
    _rCtrl.text = _fmt(rr);
    _pCtrl.text = _fmt(pp);
    setState(() => _error = null);
  }

  void _clear() {
    _uCtrl.clear();
    _iCtrl.clear();
    _rCtrl.clear();
    _pCtrl.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Законы Ома')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Заполни любые 2 поля и нажми "Рассчитать".'),
            const SizedBox(height: 10),
            _numField(_uCtrl, 'U (Вольты)'),
            const SizedBox(height: 10),
            _numField(_iCtrl, 'I (Амперы)'),
            const SizedBox(height: 10),
            _numField(_rCtrl, 'R (Омы)'),
            const SizedBox(height: 10),
            _numField(_pCtrl, 'P (Ватты)'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _solve,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Рассчитать'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _clear, child: const Text('Очистить')),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class CableSectionScreen extends StatefulWidget {
  const CableSectionScreen({super.key});

  @override
  State<CableSectionScreen> createState() => _CableSectionScreenState();
}

class _CableSectionScreenState extends State<CableSectionScreen> {
  final _currentCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  bool _isCopper = true;
  String? _result;
  String? _error;

  static const _sections = <double>[
    0.75, 1.0, 1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120
  ];

  @override
  void dispose() {
    _currentCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  double _j() => _isCopper ? 6.0 : 4.0; // A/mm² practical field rule

  double? _parse(String t) => double.tryParse(t.trim().replaceAll(',', '.'));

  void _pickSection() {
    final i = _parse(_currentCtrl.text);
    if (i == null || i <= 0) {
      setState(() {
        _error = 'Введите ток нагрузки в амперах.';
        _result = null;
      });
      return;
    }
    final need = i / _j();
    final selected = _sections.firstWhere(
      (s) => s >= need,
      orElse: () => _sections.last,
    );
    setState(() {
      _error = null;
      _result =
          'Расчётное сечение: ${need.toStringAsFixed(2)} мм²\nРекомендуемое стандартное: $selected мм² (${_isCopper ? "медь" : "алюминий"})';
    });
  }

  void _estimateCurrent() {
    final s = _parse(_sectionCtrl.text);
    if (s == null || s <= 0) {
      setState(() {
        _error = 'Введите сечение кабеля в мм².';
        _result = null;
      });
      return;
    }
    final i = s * _j();
    setState(() {
      _error = null;
      _result =
          'Оценочный допустимый ток: ${i.toStringAsFixed(1)} А (${_isCopper ? "медь" : "алюминий"})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сечение кабеля')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile.adaptive(
              value: _isCopper,
              title: Text(_isCopper ? 'Материал: медь' : 'Материал: алюминий'),
              onChanged: (v) => setState(() => _isCopper = v),
            ),
            const SizedBox(height: 8),
            const Text('1) Подбор сечения по току'),
            const SizedBox(height: 8),
            TextField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ток нагрузки, А',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickSection,
              icon: const Icon(Icons.straighten),
              label: const Text('Подобрать сечение'),
            ),
            const SizedBox(height: 14),
            const Text('2) Оценка тока по известному сечению'),
            const SizedBox(height: 8),
            TextField(
              controller: _sectionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сечение, мм²',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _estimateCurrent,
              icon: const Icon(Icons.electric_bolt),
              label: const Text('Оценить ток'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Примечание: это быстрый полевой расчёт. Для финального выбора учитывай длину линии, условия прокладки, пусковые токи и нагрев.',
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              _ResultBox(
                text: _result!,
                color: const Color(0x14FF8A3D),
                borderColor: const Color(0x44FF8A3D),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ResultBox(
                text: _error!,
                color: const Color(0x1AE35D5D),
                borderColor: const Color(0x55E35D5D),
              ),
            ],
          ],
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
