import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';

/// Efficient Supabase sync service for user profile only
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storage = StorageService();

  String? _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  String get userId {
    if (_userId == null) {
      throw Exception('User ID not set. Call setUserId() first.');
    }
    return _userId!;
  }

  // Sync user profile to cloud
  Future<void> syncUserProfile(UserProfile profile) async {
    await _supabase.from('users').upsert({
      'user_id': profile.userId,
      'profile': profile.toJson(),
      // Individual columns for queryability/analytics
      'institution': profile.institution,
      'country': profile.country,
      'institution_type': profile.institutionType,
      'major': profile.major,
      'year_of_study': profile.yearOfStudy,
      'distracting_apps': profile.distractingApps,
      'intervention_style': profile.interventionStyle,
      'enable_focus_mode': profile.enableFocusMode,
      'scroll_threshold': profile.scrollThreshold,
      'cooldown_minutes': profile.cooldownMinutes,
      'days_used': profile.daysUsed,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    await _storage.saveUserProfile(profile);
    await _storage.setLastSyncTime(DateTime.now());
  }

  // Fetch user profile from cloud
  Future<UserProfile?> fetchUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select('profile')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    final profileData = response['profile'];
    if (profileData == null) return null;

    return UserProfile.fromJson(profileData);
  }

  // Check if sync is needed
  bool needsSync({Duration threshold = const Duration(hours: 1)}) {
    final lastSync = _storage.getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > threshold;
  }
}
