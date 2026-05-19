import 'package:flutter/foundation.dart';

class SymptomRef {
  const SymptomRef({
    required this.modelId,
    required this.stepId,
  });

  final String modelId;
  final String stepId;

  String get key => '$modelId::$stepId';
}

class AppSessionStore extends ChangeNotifier {
  AppSessionStore._();

  static final AppSessionStore instance = AppSessionStore._();

  final List<SymptomRef> _recentSymptoms = [];
  final Set<String> _favoriteKeys = {};

  List<SymptomRef> get recentSymptoms => List.unmodifiable(_recentSymptoms);

  bool isFavorite(SymptomRef ref) => _favoriteKeys.contains(ref.key);

  List<SymptomRef> favoriteSymptoms(Iterable<SymptomRef> available) {
    return available.where((item) => _favoriteKeys.contains(item.key)).toList();
  }

  void recordSymptomOpen(SymptomRef ref) {
    _recentSymptoms.removeWhere((item) => item.key == ref.key);
    _recentSymptoms.insert(0, ref);
    if (_recentSymptoms.length > 8) {
      _recentSymptoms.removeLast();
    }
    notifyListeners();
  }

  void toggleFavorite(SymptomRef ref) {
    if (_favoriteKeys.contains(ref.key)) {
      _favoriteKeys.remove(ref.key);
    } else {
      _favoriteKeys.add(ref.key);
    }
    notifyListeners();
  }

  void clearRecentSymptoms() {
    _recentSymptoms.clear();
    notifyListeners();
  }
}
