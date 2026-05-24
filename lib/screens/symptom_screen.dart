import 'package:flutter/material.dart';
import '../data/app_session_store.dart';
import '../data/troubleshooting_repository.dart';
import 'pdf_viewer_screen.dart';

class SymptomScreen extends StatelessWidget {
  final String modelId;
  final String modelName;
  final TroubleshootingStep step;

  const SymptomScreen({
    super.key,
    required this.modelId,
    required this.modelName,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final symptomRef = SymptomRef(modelId: modelId, stepId: step.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(step.title),
        actions: [
          AnimatedBuilder(
            animation: AppSessionStore.instance,
            builder: (context, _) {
              final isFavorite = AppSessionStore.instance.isFavorite(symptomRef);
              return IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                onPressed: () => AppSessionStore.instance.toggleFavorite(symptomRef),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _TopInfo(modelName: modelName, unitName: step.node),
            const SizedBox(height: 12),
            if (step.symptom.isNotEmpty) ...[
              const _SectionTitle('Симптом'),
              const SizedBox(height: 8),
              _TextBlock(text: step.symptom),
            ],
            if (step.possibleCauses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Возможные причины'),
              const SizedBox(height: 8),
              ...step.possibleCauses.map((c) => _CheckRow(text: c)),
            ],
            if (step.firstChecks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Сначала проверить'),
              const SizedBox(height: 8),
              ...step.firstChecks.map((c) => _PriorityCheckRow(text: c)),
            ],
            if (step.checklist.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Что проверить'),
              const SizedBox(height: 8),
              ...step.checklist.map((c) => _CheckRow(text: c)),
            ],
            if (step.diagnosticMistakes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Типовые ошибки диагностики'),
              const SizedBox(height: 8),
              ...step.diagnosticMistakes.map((c) => _WarningRow(text: c)),
            ],
            if (step.realCases.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Реальные кейсы'),
              const SizedBox(height: 8),
              ...step.realCases.map((c) => _CaseRow(text: c)),
            ],
            if (step.measurements.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Измерения'),
              const SizedBox(height: 8),
              ...step.measurements.map((measurement) => _MeasurementCard(
                    measurement: measurement,
                  )),
            ],
            if (step.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Рекомендации'),
              const SizedBox(height: 8),
              ...step.recommendations.map((c) => _RecommendationRow(text: c)),
            ],
            if (step.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Важно'),
              const SizedBox(height: 8),
              ...step.notes.map((note) => _ImportantCard(text: note)),
            ],
            const SizedBox(height: 16),
            _PdfLaunchCard(
              isEnabled: step.pdfAsset.isNotEmpty,
              pages: step.pages,
              onTap: step.pdfAsset.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            title: 'Схема: $modelName',
                            assetPath: step.pdfAsset,
                            initialPage:
                                step.pages.isNotEmpty ? step.pages.first : 1,
                            quickPages: step.pages,
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF41281B), Color(0xFF1A2230)],
        ),
        borderRadius: BorderRadius.circular(18),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
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
        border: Border.all(color: Theme.of(context).dividerColor),
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

class _PriorityCheckRow extends StatelessWidget {
  final String text;

  const _PriorityCheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  final String text;

  const _WarningRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  final String text;

  const _CaseRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.build_circle_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final String text;

  const _RecommendationRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rule_folder_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ImportantCard extends StatelessWidget {
  final String text;

  const _ImportantCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCA28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF8D6E63)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final TroubleshootingMeasurement measurement;

  const _MeasurementCard({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(measurement.point, style: textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text('Ожидаемо: ${measurement.expected}', style: textTheme.bodyMedium),
          if (measurement.condition.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Условие: ${measurement.condition}', style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _PdfLaunchCard extends StatelessWidget {
  final bool isEnabled;
  final List<int> pages;
  final VoidCallback? onTap;

  const _PdfLaunchCard({
    required this.isEnabled,
    required this.pages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4C2B17), Color(0xFF2C313A)],
                )
              : null,
          color: isEnabled ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEnabled
                ? const Color(0x88FF7A1A)
                : Theme.of(context).dividerColor,
          ),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x14FF8A3D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FF8A3D)),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnabled ? 'Открыть схему' : 'Схема пока не привязана',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEnabled
                        ? pages.isEmpty
                            ? 'Полноэкранный просмотр PDF, поиск по тексту и удобное листание.'
                            : 'Быстрый переход на страницы: ${pages.join(', ')}'
                        : 'Для этого сценария ещё не добавлен PDF-файл или точная привязка.',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
