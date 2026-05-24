import 'package:flutter/material.dart';
import '../data/app_session_store.dart';
import '../data/troubleshooting_repository.dart';
import 'engine_codes_screen.dart';
import 'pdf_viewer_screen.dart';
import 'symptom_screen.dart';

class UnitScreen extends StatelessWidget {
  final String unitName;
  final TroubleshootingModel model;

  const UnitScreen({super.key, required this.unitName, required this.model});

  @override
  Widget build(BuildContext context) {
    final steps = model.stepsForNode(unitName);
    final normalizedUnit = unitName.toLowerCase();
    final showEngineCodes =
        _supportsCumminsCodes(model.id) && normalizedUnit.contains('двиг');
    final schemaStep = _resolveSchemaStep(steps, normalizedUnit);
    final showSchemaFirst = (normalizedUnit.contains('электр') ||
            normalizedUnit.contains('гидрав') ||
            normalizedUnit.contains('двиг')) &&
        schemaStep.pdfAsset.isNotEmpty;
    final schemaTitle = normalizedUnit.contains('гидрав')
        ? 'Открыть гидравлическую схему'
        : normalizedUnit.contains('двиг')
            ? 'Открыть схему двигателя'
            : 'Открыть электрическую схему';

    return Scaffold(
      appBar: AppBar(title: Text(unitName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _Info(
              modelName: model.displayName,
              unitName: unitName,
              count: steps.length,
            ),
            const SizedBox(height: 12),
            if (showSchemaFirst) ...[
              _SchemaFirstButton(
                title: schemaTitle,
                pages: schemaStep.pages,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Схема: ${model.displayName} · $unitName',
                      assetPath: schemaStep.pdfAsset,
                      initialPage: schemaStep.pages.isNotEmpty
                          ? schemaStep.pages.first
                          : 1,
                      quickPages: schemaStep.pages,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (showEngineCodes) ...[
              _SchemaFirstButton(
                title: 'Коды двигателя',
                description:
                    'Cummins: поиск по fault code, SPN, FMI и русскому описанию прямо в моторном разделе.',
                icon: Icons.memory_outlined,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EngineCodesScreen(modelName: model.displayName),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StepButton(
                    title: step.title,
                    subtitle: step.symptom.isNotEmpty
                        ? step.symptom
                        : 'Открыть проверки, измерения и привязку к схеме',
                    onPressed: () {
                      AppSessionStore.instance.recordSymptomOpen(
                        SymptomRef(modelId: model.id, stepId: step.id),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymptomScreen(
                            modelId: model.id,
                            modelName: model.displayName,
                            step: step,
                          ),
                        ),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  bool _supportsCumminsCodes(String modelId) {
    return modelId == 'dnk14' || modelId == 'dnk17';
  }

  TroubleshootingStep _resolveSchemaStep(
    List<TroubleshootingStep> steps,
    String normalizedUnit,
  ) {
    const empty = TroubleshootingStep(
      id: '',
      title: '',
      node: '',
      symptom: '',
      checklist: [],
      possibleCauses: [],
      firstChecks: [],
      diagnosticMistakes: [],
      realCases: [],
      measurements: [],
      recommendations: [],
      notes: [],
      pdfAsset: '',
      pages: [],
      todo: '',
    );

    final withPdf = steps.where((step) => step.pdfAsset.isNotEmpty).toList();
    if (withPdf.isEmpty) {
      return empty;
    }

    if (normalizedUnit.contains('гидрав')) {
      for (final step in withPdf) {
        if (step.pdfAsset.toLowerCase().contains('hydraulic')) {
          return step;
        }
      }
      return empty;
    }

    if (normalizedUnit.contains('двиг')) {
      for (final step in withPdf) {
        if (step.pdfAsset.toLowerCase().contains('engine_pvhc')) {
          return step;
        }
      }
      return empty;
    }

    return withPdf.first;
  }
}

class _Info extends StatelessWidget {
  final String modelName;
  final String unitName;
  final int count;

  const _Info({
    required this.modelName,
    required this.unitName,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF41281B), Color(0xFF1A2230)],
        ),
        border: Border.all(color: const Color(0x77FF7A1A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modelName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.titleLarge?.copyWith(color: const Color(0xFFFFD7B8)),
          ),
          const SizedBox(height: 6),
          Text(
            'Узел: $unitName',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodyMedium?.copyWith(color: const Color(0xFFE0E6ED)),
          ),
          const SizedBox(height: 4),
          Text(
            'Сценариев в разделе: $count',
            style: t.bodyMedium?.copyWith(color: const Color(0xFFE0E6ED)),
          ),
        ],
      ),
    );
  }
}

class _SchemaFirstButton extends StatelessWidget {
  final String title;
  final List<int> pages;
  final String? description;
  final IconData icon;
  final VoidCallback onPressed;

  const _SchemaFirstButton({
    required this.title,
    this.pages = const [],
    this.description,
    this.icon = Icons.electrical_services_outlined,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C2B17), Color(0xFF2C313A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x88FF7A1A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0x14FF8A3D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FF8A3D)),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description ??
                        (pages.isEmpty
                            ? 'Сразу перейти в PDF перед симптомами и проверками.'
                            : 'Быстрые страницы: ${pages.join(', ')}'),
                    maxLines: 4,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _StepButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x14FF8A3D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x44FF8A3D)),
              ),
              child: Icon(
                Icons.report_gmailerrorred_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 5,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
