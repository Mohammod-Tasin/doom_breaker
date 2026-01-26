import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Efficient local storage service for user profile and onboarding state
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await init();
    await prefs.setString('user_profile', jsonEncode(profile.toLocalJson()));
  }

  UserProfile? getUserProfile() {
    final jsonString = prefs.getString('user_profile');
    if (jsonString == null) return null;
    return UserProfile.fromLocalJson(jsonDecode(jsonString));
  }

  Future<void> clearUserProfile() async {
    await prefs.remove('user_profile');
  }

  // Onboarding State
  Future<void> setOnboardingComplete(bool complete) async {
    await init();
    await prefs.setBool('onboarding_complete', complete);
  }

  bool isOnboardingComplete() {
    return prefs.getBool('onboarding_complete') ?? false;
  }

  // Sync timestamp
  Future<void> setLastSyncTime(DateTime time) async {
    await init();
    await prefs.setInt('last_sync_time', time.millisecondsSinceEpoch);
  }

  DateTime? getLastSyncTime() {
    final timestamp = prefs.getInt('last_sync_time');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // Clear all data
  Future<void> clearAll() async {
    await init();
    await prefs.clear();
  }
}
