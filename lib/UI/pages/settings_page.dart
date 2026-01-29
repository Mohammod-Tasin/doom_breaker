import 'package:flutter/material.dart';
import 'package:doom_breaker/UI/Widgets/app_text.dart';
import 'package:doom_breaker/models/user_profile.dart';
import 'package:doom_breaker/services/storage_service.dart';
import 'package:doom_breaker/services/sync_service.dart';
import 'package:doom_breaker/UI/pages/onboarding/permission_guide_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String name = 'settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  final SyncService _sync = SyncService();

  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile;

  // Form State
  late TimeOfDay _studyStart;
  late TimeOfDay _studyEnd;
  late TimeOfDay _sleepStart;
  late TimeOfDay _sleepEnd;
  late TimeOfDay _institutionStart;
  late TimeOfDay _institutionEnd;
  late int _focusGoalMinutes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = _storage.getUserProfile();
    if (profile != null) {
      _initForm(profile);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } else {
      // Handle error or redirect
      Navigator.of(context).pop();
    }
  }

  void _initForm(UserProfile profile) {
    _studyStart = _parseTime(profile.studyHours.start);
    _studyEnd = _parseTime(profile.studyHours.end);
    _sleepStart = _parseTime(profile.sleepHours.start);
    _sleepEnd = _parseTime(profile.sleepHours.end);
    _institutionStart = _parseTime(profile.institutionHours.start);
    _institutionEnd = _parseTime(profile.institutionHours.end);
    _focusGoalMinutes = profile.focusGoalMinutes;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveChanges() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile = _profile!.copyWith(
        studyHours: TimeRange(
          start: _formatTime(_studyStart),
          end: _formatTime(_studyEnd),
        ),
        sleepHours: TimeRange(
          start: _formatTime(_sleepStart),
          end: _formatTime(_sleepEnd),
        ),
        institutionHours: TimeRange(
          start: _formatTime(_institutionStart),
          end: _formatTime(_institutionEnd),
        ),
        focusGoalMinutes: _focusGoalMinutes,
      );

      // Sync to Supabase
      await _sync.syncUserProfile(updatedProfile);

      // Update local state
      setState(() {
        _profile = updatedProfile;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppText.action('Settings'),
        // Let global theme handle colors
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const AppText.action('Save', color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionHeader('Schedule & Goals'),
            const SizedBox(height: 16),

            _buildTimeSection('Study Hours', _studyStart, _studyEnd, (s, e) {
              setState(() {
                _studyStart = s;
                _studyEnd = e;
              });
            }),

            _buildTimeSection('Sleep Hours', _sleepStart, _sleepEnd, (s, e) {
              setState(() {
                _sleepStart = s;
                _sleepEnd = e;
              });
            }),

            _buildTimeSection(
              'Institution Hours',
              _institutionStart,
              _institutionEnd,
              (s, e) {
                setState(() {
                  _institutionStart = s;
                  _institutionEnd = e;
                });
              },
            ),

            const SizedBox(height: 24),
            AppText.body(
              'Daily Focus Goal: ${(_focusGoalMinutes / 60).toStringAsFixed(1)} hrs',
            ),
            Slider(
              value: _focusGoalMinutes.toDouble(),
              min: 60,
              max: 720,
              divisions: 22,
              activeColor: const Color(0xFF1976D2),
              thumbColor: const Color(0xFF1976D2),
              inactiveColor: const Color(0xFF1976D2).withOpacity(0.2),
              label: '${(_focusGoalMinutes / 60).toStringAsFixed(1)} hrs',
              onChanged: (value) {
                setState(() => _focusGoalMinutes = value.round());
              },
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Permissions'),
            const SizedBox(height: 16),

            ListTile(
              title: const AppText.body('Manage Permissions'),
              subtitle: AppText.bodySmall(
                'Check and grant necessary access',
                color: const Color(0xFF546E7A),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light Blue 50
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security, color: Color(0xFF1976D2)),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.withOpacity(0.1)),
              ),
              onTap: () {
                Navigator.of(context).pushNamed(PermissionGuidePage.name);
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: AppText.bodySmall(
                'Doom Breaker v1.0.0',
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return AppText.hero(title, fontSize: 20, color: const Color(0xFF0D47A1));
  }

  Widget _buildTimeSection(
    String title,
    TimeOfDay start,
    TimeOfDay end,
    Function(TimeOfDay, TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.action(title, color: const Color(0xFF1976D2)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                'Start',
                start,
                (time) => onChanged(time, end),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimePicker(
                'End',
                end,
                (time) => onChanged(start, time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1976D2),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF0D47A1),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(label, color: const Color(0xFF546E7A)),
                const SizedBox(height: 4),
                AppText.body(
                  time.format(context),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D47A1),
                ),
              ],
            ),
            Icon(
              Icons.access_time_rounded,
              size: 20,
              color: const Color(0xFF64B5F6),
            ),
          ],
        ),
      ),
    );
  }
}
