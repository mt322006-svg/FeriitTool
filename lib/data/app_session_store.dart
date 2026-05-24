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
  final Set<int> _favoriteFaultCodes = {};

  List<SymptomRef> get recentSymptoms => List.unmodifiable(_recentSymptoms);
  List<int> get favoriteFaultCodes => _favoriteFaultCodes.toList()
    ..sort((left, right) => left.compareTo(right));

  bool isFavorite(SymptomRef ref) => _favoriteKeys.contains(ref.key);
  bool isFavoriteFaultCode(int faultCode) =>
      _favoriteFaultCodes.contains(faultCode);

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

  void toggleFavoriteFaultCode(int faultCode) {
    if (_favoriteFaultCodes.contains(faultCode)) {
      _favoriteFaultCodes.remove(faultCode);
    } else {
      _favoriteFaultCodes.add(faultCode);
    }
    notifyListeners();
  }

  void clearRecentSymptoms() {
    _recentSymptoms.clear();
    notifyListeners();
  }
}
