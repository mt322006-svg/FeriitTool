import 'package:flutter/material.dart';

import 'data/app_settings_store.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppSettingsStore.instance.ensureLoaded();
  runApp(const FerritToolApp());
}

class FerritToolApp extends StatelessWidget {
  const FerritToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettingsStore.instance,
      builder: (context, _) {
        final settings = AppSettingsStore.instance;
        final themeMode = settings.themePreference == AppThemePreference.light
            ? ThemeMode.light
            : ThemeMode.dark;
        final textScale = settings.largeTextEnabled ? 1.16 : 1.0;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Твой Ferrrit',
          theme: buildLightAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
