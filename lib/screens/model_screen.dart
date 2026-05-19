import 'package:flutter/material.dart';
import '../data/troubleshooting_repository.dart';
import 'engine_codes_screen.dart';
import 'unit_screen.dart';

class ModelScreen extends StatelessWidget {
  final TroubleshootingModel model;
  const ModelScreen({super.key, required this.model});

  bool get _supportsCumminsCodes => model.id == 'dnk14' || model.id == 'dnk17';
  bool get _isSimpleEngineModel => model.id == 'dnk10';

  @override
  Widget build(BuildContext context) {
    final units = model.nodes;

    return Scaffold(
      appBar: AppBar(title: Text(model.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _ModelHero(
              title: model.displayName,
              subtitle: _supportsCumminsCodes
                  ? 'Полевая диагностика, схемы и коды Cummins для электронной серии.'
                  : _isSimpleEngineModel
                      ? 'Базовая серия без полноценного ECU-справочника Cummins.'
                      : 'Полевая диагностика и схемы для сервисной работы.',
            ),
            const SizedBox(height: 12),
            if (_supportsCumminsCodes)
              _ServiceToolCard(
                title: 'Коды двигателя Cummins',
                subtitle:
                    'Поиск по fault code, SPN, FMI и описанию для серий ПДМ-14 / ПДМ-17.',
                buttonLabel: 'Открыть коды',
                icon: Icons.memory_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EngineCodesScreen(modelName: model.displayName),
                  ),
                ),
              ),
            if (_isSimpleEngineModel)
              const _InfoNote(
                title: 'По двигателю',
                text:
                    'ПДМ-10 идёт как более простая машина без такого ECU-сценария, поэтому раздел Cummins-кодов сюда не подтягиваем.',
              ),
            if (_supportsCumminsCodes || _isSimpleEngineModel)
              const SizedBox(height: 12),
            Text(
              'Узлы и разделы',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...units.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SectionButton(
                icon: Icons.layers_outlined,
                title: u,
                subtitle: 'Открыть симптоматику и проверки по узлу',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnitScreen(unitName: u, model: model),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ModelHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ModelHero({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ServiceToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceToolCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String title;
  final String text;

  const _InfoNote({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _SectionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
