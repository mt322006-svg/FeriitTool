import 'package:flutter/material.dart';
import 'pdf_viewer_screen.dart';

class SymptomScreen extends StatelessWidget {
  final String modelName;
  final String unitName;
  final String symptom;

  const SymptomScreen({
    super.key,
    required this.modelName,
    required this.unitName,
    required this.symptom,
  });

  @override
  Widget build(BuildContext context) {
    final pdfAssetPath = _guessPdfForModel(modelName);
    final checks = _defaultChecklist(unitName, symptom);

    return Scaffold(
      appBar: AppBar(title: Text(symptom)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _TopInfo(modelName: modelName, unitName: unitName),
            const SizedBox(height: 12),
            _SectionTitle('Что проверить'),
            const SizedBox(height: 8),
            ...checks.map((c) => _CheckRow(text: c)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Схема: $modelName',
                      assetPath: pdfAssetPath,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Открыть схему'),
            ),
          ],
        ),
      ),
    );
  }

  static String _guessPdfForModel(String modelName) {
    if (modelName.contains('DNK 10')) return 'assets/pdfs/dnk10_schema.pdf';
    if (modelName.contains('DNK 14')) return 'assets/pdfs/dnk14_schema.pdf';
    return 'assets/pdfs/dnk17_schema.pdf';
  }

  static List<String> _defaultChecklist(String unitName, String symptom) {
    if (unitName == 'Освещение' && symptom.contains('фары')) {
      return const [
        'Предохранитель цепи освещения',
        'Реле/модуль управления (если есть по схеме)',
        'Разъём KP09 (контакт/окисление)',
        'Наличие +24V и целостность массы',
      ];
    }
    return const [
      'Питание / масса',
      'Разъёмы и жгут на повреждения',
      'Предохранители',
      'Управляющий сигнал (если предусмотрен)',
    ];
  }
}

class _TopInfo extends StatelessWidget {
  final String modelName;
  final String unitName;

  const _TopInfo({required this.modelName, required this.unitName});

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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
