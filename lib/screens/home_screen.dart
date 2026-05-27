import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_session_store.dart';
import '../data/sensor_catalog_repository.dart';
import '../data/troubleshooting_repository.dart';
import 'engine_codes_screen.dart';
import 'ferrit_codes_screen.dart';
import 'global_search_screen.dart';
import 'model_screen.dart';
import 'settings_screen.dart';
import 'sensors_screen.dart';
import 'symptom_screen.dart';
import 'tetris_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _easterTapCount = 0;
  Timer? _easterTapTimer;

  @override
  void initState() {
    super.initState();
  }

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
    _easterTapTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 46,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: _AnimatedFerritEmblem(
            onTap: _onEmblemTap,
          ),
        ),
        title: Text(
          'Твой Ferrrit',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        titleSpacing: 8,
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
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

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _ActionCard(
                    icon: Icons.manage_search,
                    title: 'Поиск',
                    subtitle: 'Симптомы, коды, датчики',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    title: 'Серии техники',
                    subtitle: 'Выбери машину и переходи к симптомам и схемам.',
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
                  const SizedBox(height: 4),
                  const _SectionTitle(
                    title: 'Датчики и калькуляторы',
                    subtitle: 'Быстрый вход в базу датчиков, RTD/NTC и расчёты.',
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.thermostat_outlined,
                    title: 'Открыть датчики и калькуляторы',
                    subtitle: 'Справочник датчиков, калькуляция сопротивления и температуры.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SensorsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    title: 'Коды Ferrit',
                    subtitle: 'Общий справочник кодов ошибок Ferrit по номеру.',
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Открыть коды Ferrit',
                    subtitle: 'Вводи номер (например 21) или листай весь список.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FerritCodesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    title: 'Коды двигателя',
                    subtitle: 'Cummins для ПДМ-14/17 и электронной серии.',
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.memory_outlined,
                    title: 'Открыть коды двигателя',
                    subtitle: 'Поиск по Fault, SPN, FMI и русскому описанию.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EngineCodesScreen(
                          modelName: 'ПДМ-14 / ПДМ-17',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactSymptomSection(
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onEmblemTap() {
    _easterTapCount++;
    _easterTapTimer?.cancel();
    _easterTapTimer = Timer(const Duration(milliseconds: 900), () {
      _easterTapCount = 0;
    });
    if (_easterTapCount >= 3) {
      _easterTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TetrisScreen()),
      );
    }
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

}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
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
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
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
                  Text(
                    model.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
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
                              Text(
                                item.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium,
                              ),
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

class _AnimatedFerritEmblem extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedFerritEmblem({required this.onTap});

  @override
  State<_AnimatedFerritEmblem> createState() => _AnimatedFerritEmblemState();
}

class _AnimatedFerritEmblemState extends State<_AnimatedFerritEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          final bucketAngle = (-0.95 + t * 1.55);
          final bucketDy = -4.0 + t * 7.0;
          final bodyDy = (t - 0.5) * 1.6;
          return SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, bodyDy),
                  child: Icon(
                    Icons.construction_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 10 + bodyDy,
                  child: Container(
                    width: 14,
                    height: 2,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 8 + bucketDy + bodyDy,
                  child: Transform.rotate(
                    angle: bucketAngle,
                    child: Container(
                      width: 12,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
