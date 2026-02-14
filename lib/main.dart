import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FerritToolApp());
}

class FerritToolApp extends StatelessWidget {
  const FerritToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ferrit Tool',
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
