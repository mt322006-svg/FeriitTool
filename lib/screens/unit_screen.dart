import 'package:flutter/material.dart';
import 'symptom_screen.dart';

class UnitScreen extends StatelessWidget {
  final String unitName;
  final String modelName;

  const UnitScreen({super.key, required this.unitName, required this.modelName});

  @override
  Widget build(BuildContext context) {
    final symptoms = (unitName == 'Освещение')
        ? const ['Не работают фары на стреле (низ)', 'Не работает габарит', 'Моргает/пропадает свет']
        : const ['Нет питания', 'Не запускается', 'Срабатывает защита'];

    return Scaffold(
      appBar: AppBar(title: Text(unitName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _Info(modelName: modelName, unitName: unitName),
            const SizedBox(height: 12),
            ...symptoms.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SymptomScreen(modelName: modelName, unitName: unitName, symptom: s)),
                ),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                child: Row(
                  children: [
                    const Icon(Icons.report_gmailerrorred_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String modelName;
  final String unitName;
  const _Info({required this.modelName, required this.unitName});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modelName, style: t.titleLarge),
          const SizedBox(height: 6),
          Text('Узел: $unitName', style: t.bodyMedium),
        ],
      ),
    );
  }
}
