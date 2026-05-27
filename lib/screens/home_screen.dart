import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_settings_store.dart';
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
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        centerTitle: false,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTitleTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Твой Ferrrit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              const _SegmentClock(),
            ],
          ),
        ),
        titleSpacing: 14,
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
            animation: Listenable.merge([
              AppSessionStore.instance,
              AppSettingsStore.instance,
            ]),
            builder: (context, _) {
              final recentRefs = AppSessionStore.instance.recentSymptoms;
              final brightness = Theme.of(context).brightness;
              final showHeaders = AppSettingsStore.instance.showSectionHeaders;

              return Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CircuitBoardBackgroundPainter(
                          isDark: brightness == Brightness.dark,
                        ),
                      ),
                    ),
                  ),
                  ListView(
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
                      if (showHeaders) ...[
                        const _SectionTitle(
                          title: 'Серии техники',
                          subtitle:
                              'Выбери машину и переходи к симптомам и схемам.',
                        ),
                        const SizedBox(height: 10),
                      ],
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
                      if (showHeaders) ...[
                        const _SectionTitle(
                          title: 'Датчики и калькуляторы',
                          subtitle:
                              'Быстрый вход в базу датчиков, RTD/NTC и расчёты.',
                        ),
                        const SizedBox(height: 10),
                      ],
                      _ActionCard(
                        icon: Icons.thermostat_outlined,
                        title: 'Открыть датчики и калькуляторы',
                        subtitle:
                            'Справочник датчиков, калькуляция сопротивления и температуры.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SensorsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (showHeaders) ...[
                        const _SectionTitle(
                          title: 'Коды Ferrit',
                          subtitle:
                              'Общий справочник кодов ошибок Ferrit по номеру.',
                        ),
                        const SizedBox(height: 10),
                      ],
                      _ActionCard(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Открыть коды Ferrit',
                        subtitle:
                            'Вводи номер (например 21) или листай весь список.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FerritCodesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (showHeaders) ...[
                        const _SectionTitle(
                          title: 'Коды двигателя',
                          subtitle:
                              'Cummins для ПДМ-14/17 и электронной серии.',
                        ),
                        const SizedBox(height: 10),
                      ],
                      _ActionCard(
                        icon: Icons.memory_outlined,
                        title: 'Открыть коды двигателя',
                        subtitle:
                            'Поиск по Fault, SPN, FMI и русскому описанию.',
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
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onTitleTap() {
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

class _HomeData {
  const _HomeData({
    required this.troubleshooting,
    required this.sensors,
  });

  final TroubleshootingCatalog troubleshooting;
  final SensorCatalog sensors;
}

class _SegmentClock extends StatefulWidget {
  const _SegmentClock();

  @override
  State<_SegmentClock> createState() => _SegmentClockState();
}

class _SegmentClockState extends State<_SegmentClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegDigit(value: hh[0], color: accent),
          const SizedBox(width: 3),
          _SegDigit(value: hh[1], color: accent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                color: accent.withValues(alpha: 0.95),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          _SegDigit(value: mm[0], color: accent),
          const SizedBox(width: 3),
          _SegDigit(value: mm[1], color: accent),
        ],
      ),
    );
  }
}

class _SegDigit extends StatelessWidget {
  const _SegDigit({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 13,
      child: CustomPaint(
        painter: _SegDigitPainter(value: value, color: color),
      ),
    );
  }
}

class _SegDigitPainter extends CustomPainter {
  const _SegDigitPainter({required this.value, required this.color});

  final String value;
  final Color color;

  static const _map = <String, List<bool>>{
    '0': [true, true, true, true, true, true, false],
    '1': [false, true, true, false, false, false, false],
    '2': [true, true, false, true, true, false, true],
    '3': [true, true, true, true, false, false, true],
    '4': [false, true, true, false, false, true, true],
    '5': [true, false, true, true, false, true, true],
    '6': [true, false, true, true, true, true, true],
    '7': [true, true, true, false, false, false, false],
    '8': [true, true, true, true, true, true, true],
    '9': [true, true, true, true, false, true, true],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final on = _map[value] ?? _map['0']!;
    final onPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    final offPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final t = math.max(1.6, w * 0.22);

    final seg = <RRect>[
      RRect.fromRectAndRadius(
          Rect.fromLTWH(t, 0, w - 2 * t, t), const Radius.circular(1.2)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w - t, t, t, h / 2 - t), const Radius.circular(1.2)),
      RRect.fromRectAndRadius(Rect.fromLTWH(w - t, h / 2, t, h / 2 - t),
          const Radius.circular(1.2)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(t, h - t, w - 2 * t, t), const Radius.circular(1.2)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h / 2, t, h / 2 - t), const Radius.circular(1.2)),
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, t, t, h / 2 - t), const Radius.circular(1.2)),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(t, h / 2 - t / 2, w - 2 * t, t),
        const Radius.circular(1.2),
      ),
    ];

    for (var i = 0; i < seg.length; i++) {
      canvas.drawRRect(seg[i], on[i] ? onPaint : offPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegDigitPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _CircuitBoardBackgroundPainter extends CustomPainter {
  const _CircuitBoardBackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFF6F7B89) : const Color(0xFF8B755F))
          .withValues(alpha: isDark ? 0.12 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final padPaint = Paint()
      ..color = (isDark ? const Color(0xFFFF8A3D) : const Color(0xFFD46A1E))
          .withValues(alpha: isDark ? 0.1 : 0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.18)
      ..lineTo(size.width * 0.38, size.height * 0.18)
      ..lineTo(size.width * 0.38, size.height * 0.12)
      ..lineTo(size.width * 0.72, size.height * 0.12)
      ..lineTo(size.width * 0.72, size.height * 0.28)
      ..lineTo(size.width * 0.94, size.height * 0.28);
    canvas.drawPath(path1, linePaint);

    final path2 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.52)
      ..lineTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.3, size.height * 0.46)
      ..lineTo(size.width * 0.55, size.height * 0.46)
      ..lineTo(size.width * 0.55, size.height * 0.62)
      ..lineTo(size.width * 0.88, size.height * 0.62);
    canvas.drawPath(path2, linePaint);

    final path3 = Path()
      ..moveTo(size.width * 0.16, size.height * 0.84)
      ..lineTo(size.width * 0.4, size.height * 0.84)
      ..lineTo(size.width * 0.4, size.height * 0.76)
      ..lineTo(size.width * 0.82, size.height * 0.76);
    canvas.drawPath(path3, linePaint);

    final points = <Offset>[
      Offset(size.width * 0.38, size.height * 0.18),
      Offset(size.width * 0.72, size.height * 0.12),
      Offset(size.width * 0.72, size.height * 0.28),
      Offset(size.width * 0.3, size.height * 0.52),
      Offset(size.width * 0.55, size.height * 0.46),
      Offset(size.width * 0.55, size.height * 0.62),
      Offset(size.width * 0.4, size.height * 0.84),
      Offset(size.width * 0.4, size.height * 0.76),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 4.2, padPaint);
      canvas.drawCircle(point, 2.2, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitBoardBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
