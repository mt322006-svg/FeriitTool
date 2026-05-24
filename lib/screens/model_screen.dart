import 'package:flutter/material.dart';
import '../data/troubleshooting_repository.dart';
import 'pdf_viewer_screen.dart';
import 'unit_screen.dart';

class ModelScreen extends StatelessWidget {
  final TroubleshootingModel model;
  const ModelScreen({super.key, required this.model});

  bool get _supportsCumminsCodes => model.id == 'dnk14' || model.id == 'dnk17';
  bool get _isSimpleEngineModel => model.id == 'dnk10';

  String? get _maintenancePdfAsset {
    switch (model.id) {
      case 'dnk10':
        return 'assets/pdfs/dnk10_maintenance_ru.pdf';
      case 'dnk14':
        return 'assets/pdfs/dnk14_maintenance_ru.pdf';
      case 'dnk17':
        return 'assets/pdfs/dnk17_maintenance_ru.pdf';
      case 'shs30':
        return 'assets/pdfs/shs30_maintenance_ru.pdf';
      default:
        return null;
    }
  }

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
            if (_maintenancePdfAsset != null) ...[
              _ServiceToolCard(
                title: 'Карта ТО и фильтры',
                subtitle:
                    'Открыть сервисную карту ТО по модели, чтобы быстро смотреть обслуживание и фильтры.',
                buttonLabel: 'Открыть карту ТО',
                icon: Icons.fact_check_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Карта ТО: ${model.displayName}',
                      assetPath: _maintenancePdfAsset!,
                    ),
                  ),
                ),
              ),
            ],
            if (_isSimpleEngineModel)
              const _InfoNote(
                title: 'По двигателю',
                text:
                    'ПДМ-10 идёт как более простая машина без такого ECU-сценария, поэтому раздел Cummins-кодов сюда не подтягиваем.',
              ),
            if (_isSimpleEngineModel) const SizedBox(height: 12),
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
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFD7B8),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE0E6ED),
                ),
          ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(
                buttonLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
            ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
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
                    subtitle,
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
