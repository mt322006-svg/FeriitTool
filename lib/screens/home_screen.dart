import 'package:flutter/material.dart';
import 'model_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final machines = const [
      'Ferrit DNK 10',
      'Ferrit DNK 14',
      'Ferrit DNK 17',
      // Самосвал добавим позже
    ];

    return Scaffold(
      appBar: AppBar(
      title: Text(
        'FERRIT TOOL',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _Header(
              title: 'Выбери технику',
              subtitle: 'Оффлайн диагностика + схемы',
            ),
            const SizedBox(height: 16),
            ...machines.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BigButton(
                title: m,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ModelScreen(modelName: m)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

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
          Text(title, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: t.bodyMedium),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _BigButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
      ),
      child: Row(
        children: [
          const Icon(Icons.construction_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
