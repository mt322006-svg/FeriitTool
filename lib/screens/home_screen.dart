import 'package:flutter/material.dart';

import '../data/app_session_store.dart';
import '../data/sensor_catalog_repository.dart';
import '../data/troubleshooting_repository.dart';
import 'engine_codes_screen.dart';
import 'global_search_screen.dart';
import 'model_screen.dart';
import 'sensors_screen.dart';
import 'symptom_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _recentKey = GlobalKey();

  Future<_HomeData> _loadHomeData() async {
    final troubleshooting =
        await TroubleshootingRepository.instance.loadCatalog();
    final sensors = await SensorCatalogRepository.instance.loadCatalog();
    return _HomeData(
      troubleshooting: troubleshooting,
      sensors: sensors,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FERRIT TOOL',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
      body: FutureBuilder<_HomeData>(
        future: _loadHomeData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ErrorState(
              message: 'Не удалось загрузить стартовые данные.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final homeData = snapshot.data!;
          final catalog = homeData.troubleshooting;

          return AnimatedBuilder(
            animation: AppSessionStore.instance,
            builder: (context, _) {
              final recentRefs = AppSessionStore.instance.recentSymptoms;
              final availableRefs = [
                for (final model in catalog.models)
                  for (final step in model.steps)
                    SymptomRef(modelId: model.id, stepId: step.id),
              ];
              final favoriteRefs =
                  AppSessionStore.instance.favoriteSymptoms(availableRefs);

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  const _HeroPanel(
                    title: 'Инструмент для сервисников',
                    subtitle:
                        'Диагностика, схемы, коды двигателя и датчики в одном оффлайн-наборе.',
                  ),
                  const SizedBox(height: 14),
                  _QuickTools(
                    onSearch: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchScreen(),
                      ),
                    ),
                    onSensors: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SensorsScreen(),
                      ),
                    ),
                    onCodes: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EngineCodesScreen(
                          modelName: 'ПДМ-14 / ПДМ-17',
                        ),
                      ),
                    ),
                    onRecent: _scrollToRecent,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Серии техники',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ...catalog.models.map(
                    (model) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModelCard(
                        model: model,
                        subtitle: _modelSubtitle(model.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModelScreen(model: model),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactSymptomSection(
                    title: 'Избранное',
                    emptyText:
                        'Пока пусто. Открой нужный симптом и нажми звезду, чтобы закрепить его здесь.',
                    items: favoriteRefs
                        .map((ref) => _resolveSymptomCard(catalog, ref))
                        .whereType<_ResolvedSymptomCard>()
                        .toList(growable: false),
                    onClear: null,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: _recentKey,
                    child: _CompactSymptomSection(
                      title: 'Последние открытия',
                      emptyText:
                          'Здесь появятся последние открытые симптомы и проверки.',
                      items: recentRefs
                          .map((ref) => _resolveSymptomCard(catalog, ref))
                          .whereType<_ResolvedSymptomCard>()
                          .toList(growable: false),
                      onClear: recentRefs.isEmpty
                          ? null
                          : AppSessionStore.instance.clearRecentSymptoms,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _AboutBlock(
                    title: 'О программе',
                    text:
                        'С уважением и пониманием к сервису.\nСоздатель MobileTechnology (РябкоFF)',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _modelSubtitle(String modelId) {
    switch (modelId) {
      case 'dnk10':
        return 'Простая серия · диагностика и электрические схемы';
      case 'dnk14':
      case 'dnk17':
        return 'Электронная серия + Cummins · диагностика, схемы и fault codes';
      case 'shs30':
        return 'Шахтная серия · диагностика и электрические схемы';
      default:
        return 'Диагностика и электрические схемы';
    }
  }

  _ResolvedSymptomCard? _resolveSymptomCard(
    TroubleshootingCatalog catalog,
    SymptomRef ref,
  ) {
    final model = catalog.findById(ref.modelId);
    final step = model?.stepById(ref.stepId);
    if (model == null || step == null) {
      return null;
    }
    return _ResolvedSymptomCard(
      title: '${model.displayName} · ${step.title}',
      subtitle: step.node,
      onTap: () {
        AppSessionStore.instance.recordSymptomOpen(ref);
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
    );
  }

  void _scrollToRecent() {
    final targetContext = _recentKey.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F3745), Color(0xFF1C2230)],
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

class _QuickTools extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onSensors;
  final VoidCallback onCodes;
  final VoidCallback onRecent;

  const _QuickTools({
    required this.onSearch,
    required this.onSensors,
    required this.onCodes,
    required this.onRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые инструменты',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _ToolTile(
              icon: Icons.manage_search,
              title: 'Поиск',
              subtitle: 'Симптомы, коды, датчики',
              onTap: onSearch,
            ),
            _ToolTile(
              icon: Icons.thermostat_outlined,
              title: 'Датчики',
              subtitle: 'RTD, NTC и калькуляторы',
              onTap: onSensors,
            ),
            _ToolTile(
              icon: Icons.memory_outlined,
              title: 'Коды двигателя',
              subtitle: 'Cummins для 14 / 17 серии',
              onTap: onCodes,
            ),
            _ToolTile(
              icon: Icons.history,
              title: 'Последние',
              subtitle: 'Вернуться к недавним открытиям',
              onTap: onRecent,
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x14FF8A3D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x44FF8A3D)),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final TroubleshootingModel model;
  final String subtitle;
  final VoidCallback onTap;

  const _ModelCard({
    required this.model,
    required this.subtitle,
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
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
                Icons.construction_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.displayName, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _CompactSymptomSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<_ResolvedSymptomCard> items;
  final VoidCallback? onClear;

  const _CompactSymptomSection({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (onClear != null)
                TextButton(
                  onPressed: onClear,
                  child: const Text('Очистить'),
                ),
            ],
          ),
          if (items.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0x14FF8A3D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x44FF8A3D)),
                          ),
                          child: Icon(
                            Icons.topic_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 3),
                              Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResolvedSymptomCard {
  const _ResolvedSymptomCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AboutBlock extends StatelessWidget {
  final String title;
  final String text;

  const _AboutBlock({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.troubleshooting,
    required this.sensors,
  });

  final TroubleshootingCatalog troubleshooting;
  final SensorCatalog sensors;
}
