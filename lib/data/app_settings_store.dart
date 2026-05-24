import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  dark,
  light,
}

class PdfViewState {
  const PdfViewState({
    required this.page,
    required this.zoom,
  });

  final int page;
  final double zoom;
}

class AppSettingsStore extends ChangeNotifier {
  AppSettingsStore._();

  static final AppSettingsStore instance = AppSettingsStore._();

  static const _keepScreenAwakeKey = 'keep_screen_awake_in_pdf';
  static const _largeTextKey = 'large_text_enabled';
  static const _showQuickToolsKey = 'show_quick_tools';
  static const _themeKey = 'theme_preference';
  static const _pdfPagePrefix = 'pdf_page::';
  static const _pdfZoomPrefix = 'pdf_zoom::';

  bool _isLoaded = false;
  bool _keepScreenAwakeInPdf = true;
  bool _largeTextEnabled = false;
  bool _showQuickTools = true;
  AppThemePreference _themePreference = AppThemePreference.dark;
  SharedPreferences? _prefs;

  bool get isLoaded => _isLoaded;
  bool get keepScreenAwakeInPdf => _keepScreenAwakeInPdf;
  bool get largeTextEnabled => _largeTextEnabled;
  bool get showQuickTools => _showQuickTools;
  AppThemePreference get themePreference => _themePreference;

  Future<void> ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _keepScreenAwakeInPdf = prefs.getBool(_keepScreenAwakeKey) ?? true;
    _largeTextEnabled = prefs.getBool(_largeTextKey) ?? false;
    _showQuickTools = prefs.getBool(_showQuickToolsKey) ?? true;
    _themePreference = _readThemePreference(
      prefs.getString(_themeKey),
    );
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setKeepScreenAwakeInPdf(bool value) async {
    await ensureLoaded();
    if (_keepScreenAwakeInPdf == value) {
      return;
    }
    _keepScreenAwakeInPdf = value;
    notifyListeners();
    await _prefs!.setBool(_keepScreenAwakeKey, value);
  }

  Future<void> setLargeTextEnabled(bool value) async {
    await ensureLoaded();
    if (_largeTextEnabled == value) {
      return;
    }
    _largeTextEnabled = value;
    notifyListeners();
    await _prefs!.setBool(_largeTextKey, value);
  }

  Future<void> setShowQuickTools(bool value) async {
    await ensureLoaded();
    if (_showQuickTools == value) {
      return;
    }
    _showQuickTools = value;
    notifyListeners();
    await _prefs!.setBool(_showQuickToolsKey, value);
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    await ensureLoaded();
    if (_themePreference == value) {
      return;
    }
    _themePreference = value;
    notifyListeners();
    await _prefs!.setString(_themeKey, value.name);
  }

  Future<void> savePdfViewState(
    String assetPath, {
    required int page,
    required double zoom,
  }) async {
    await ensureLoaded();
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedZoom = zoom < 1.0 ? 1.0 : zoom;
    final suffix = Uri.encodeComponent(assetPath);
    await _prefs!.setInt('$_pdfPagePrefix$suffix', normalizedPage);
    await _prefs!.setDouble('$_pdfZoomPrefix$suffix', normalizedZoom);
  }

  Future<PdfViewState?> loadPdfViewState(String assetPath) async {
    await ensureLoaded();
    final suffix = Uri.encodeComponent(assetPath);
    final page = _prefs!.getInt('$_pdfPagePrefix$suffix');
    final zoom = _prefs!.getDouble('$_pdfZoomPrefix$suffix');
    if (page == null && zoom == null) {
      return null;
    }
    return PdfViewState(
      page: page == null || page < 1 ? 1 : page,
      zoom: zoom == null || zoom < 1.0 ? 1.0 : zoom,
    );
  }

  AppThemePreference _readThemePreference(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
      default:
        return AppThemePreference.dark;
    }
  }
}
