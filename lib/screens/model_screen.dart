import 'package:flutter/material.dart';
import 'unit_screen.dart';

class ModelScreen extends StatelessWidget {
  final String modelName;
  const ModelScreen({super.key, required this.modelName});

  @override
  Widget build(BuildContext context) {
    final units = const [
      'Электрика',
      'Освещение',
      'Гидравлика',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(modelName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 4),
            ...units.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UnitScreen(unitName: u, modelName: modelName)),
                ),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(u)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
