// lib/services/progress_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProgressService extends ChangeNotifier {
  late SharedPreferences _prefs;
  UserProfile _profile = UserProfile(lastPlayDate: DateTime.now());

  UserProfile get profile => _profile;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
  }

  Future<void> _loadProgress() async {
    final xp = _prefs.getInt('xp') ?? 0;
    final hearts = _prefs.getInt('hearts') ?? 5;
    final streak = _prefs.getInt('streakDays') ?? 0;
    final lastPlayMs = _prefs.getInt('lastPlayDate');
    
    DateTime lastPlay = DateTime.now();
    if (lastPlayMs != null) {
      lastPlay = DateTime.fromMillisecondsSinceEpoch(lastPlayMs);
    }

    _profile = UserProfile(
      xp: xp,
      hearts: hearts,
      streakDays: streak,
      lastPlayDate: lastPlay,
    );
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    _profile = _profile.copyWith(xp: _profile.xp + amount);
    await _prefs.setInt('xp', _profile.xp);
    notifyListeners();
  }

  Future<void> deductHeart() async {
    if (_profile.hearts > 0) {
      _profile = _profile.copyWith(hearts: _profile.hearts - 1);
      await _prefs.setInt('hearts', _profile.hearts);
      notifyListeners();
    }
  }

  Future<void> addHeart() async {
    if (_profile.hearts < 5) {
      _profile = _profile.copyWith(hearts: _profile.hearts + 1);
      await _prefs.setInt('hearts', _profile.hearts);
      notifyListeners();
    }
  }
}
