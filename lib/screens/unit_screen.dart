import 'package:flutter/material.dart';
import '../data/app_session_store.dart';
import '../data/troubleshooting_repository.dart';
import 'symptom_screen.dart';

class UnitScreen extends StatelessWidget {
  final String unitName;
  final TroubleshootingModel model;

  const UnitScreen({super.key, required this.unitName, required this.model});

  @override
  Widget build(BuildContext context) {
    final steps = model.stepsForNode(unitName);

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
          colors: [Color(0xFF323844), Color(0xFF1F242B)],
        ),
        border: Border.all(color: const Color(0x44FF8A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modelName, style: t.titleLarge),
          const SizedBox(height: 6),
          Text('Узел: $unitName', style: t.bodyMedium),
          const SizedBox(height: 4),
          Text('Сценариев в разделе: $count', style: t.bodyMedium),
        ],
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(84),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.report_gmailerrorred_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
