import 'package:flutter/material.dart';
import 'package:doom_breaker/UI/Widgets/app_text.dart';
import 'package:doom_breaker/UI/pages/welcome_page.dart';
import 'package:doom_breaker/services/platform_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionGuidePage extends StatefulWidget {
  const PermissionGuidePage({super.key});

  static const String name = 'permissions';

  @override
  State<PermissionGuidePage> createState() => _PermissionGuidePageState();
}

class _PermissionGuidePageState extends State<PermissionGuidePage>
    with WidgetsBindingObserver {
  final PlatformService _platform = PlatformService();

  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _accessibilityGranted = false;
  bool _notificationGranted = false;
  bool _batteryOptimizationGranted = false;
  bool _autoStartGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes (user comes back from settings), re-check permissions
    if (state == AppLifecycleState.resumed) {
      // Small delay to let system update permission status
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkPermissions();
        }
      });
    }
  }

  Future<void> _checkPermissions() async {
    final permissions = await _platform.checkAllPermissions();
    final notifStatus = await Permission.notification.status;

    setState(() {
      _usageStatsGranted = permissions['usageStats'] ?? false;
      _overlayGranted = permissions['overlay'] ?? false;
      _accessibilityGranted = permissions['accessibility'] ?? false;
      _batteryOptimizationGranted = permissions['batteryOptimization'] ?? false;
      _autoStartGranted = permissions['autoStart'] ?? false;
      _notificationGranted = notifStatus.isGranted;
    });
  }

  bool get _allGranted =>
      _usageStatsGranted &&
      _overlayGranted &&
      _accessibilityGranted &&
      _notificationGranted &&
      _batteryOptimizationGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AppText.action(
          'Permissions Setup',
          color: Color(0xFF0D47A1),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 64,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AppText.hero(
                    'Grant Permissions',
                    textAlign: TextAlign.center,
                    color: Color(0xFF0D47A1),
                  ),
                  const SizedBox(height: 12),
                  AppText.body(
                    'Doom Breaker needs these permissions to monitor your app usage and help you stay focused.',
                    textAlign: TextAlign.center,
                    color: const Color(0xFF546E7A),
                  ),
                  const SizedBox(height: 40),

                  _buildPermissionCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Usage Access',
                    description:
                        'Allows monitoring which apps you use and for how long',
                    isGranted: _usageStatsGranted,
                    onRequest: () async {
                      await _platform.requestUsageStatsPermission();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPermissionCard(
                    icon: Icons.layers_outlined,
                    title: 'Display Over Apps',
                    description:
                        'Shows gentle reminders when you need to refocus',
                    isGranted: _overlayGranted,
                    onRequest: () async {
                      await _platform.requestOverlayPermission();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPermissionCard(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Accessibility Service',
                    description:
                        'Detects scroll patterns to identify distracting content',
                    isGranted: _accessibilityGranted,
                    onRequest: () async {
                      await _platform.requestAccessibilityPermission();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPermissionCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    description:
                        'Allows sending focus reminders and motivational messages',
                    isGranted: _notificationGranted,
                    onRequest: () async {
                      await Permission.notification.request();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPermissionCard(
                    icon: Icons.battery_charging_full_rounded,
                    title: 'Battery Optimization',
                    description:
                        'Prevents the app from being killed in background',
                    isGranted: _batteryOptimizationGranted,
                    onRequest: () async {
                      await _platform.requestBatteryOptimization();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPermissionCard(
                    icon: Icons.power_settings_new_rounded,
                    title: 'Auto-Start Permission',
                    description:
                        'Allows the app to start automatically when device boots',
                    isGranted: _autoStartGranted,
                    onRequest: () async {
                      await _platform.requestAutoStartPermission();
                    },
                  ),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppText.bodySmall(
                            'All data stays on your device. We never collect personal information.',
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(WelcomePage.name);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AppText.action(
                      _allGranted ? 'Continue to App' : 'Skip for now',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF42A5F5)
              : const Color(0xFFD32F2F), // Red border for ungranted
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isGranted
                ? Colors.blue.withOpacity(0.1)
                : Colors.red.withOpacity(0.15), // Red shadow for ungranted
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFFFEBEE), // Light red for ungranted
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFD32F2F), // Red icon for ungranted
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppText.action(
                  title,
                  color: isGranted
                      ? const Color(0xFF0D47A1)
                      : const Color(0xFFD32F2F), // Red title for ungranted
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF1976D2))
              else
                const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFD32F2F),
                  size: 28,
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppText.bodySmall(description, color: const Color(0xFF546E7A)),
          if (!isGranted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const AppText.action(
                  'Grant Permission',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
