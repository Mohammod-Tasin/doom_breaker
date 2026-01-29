import 'package:flutter/material.dart';
import 'package:doom_breaker/UI/pages/login_page.dart';
import 'package:doom_breaker/services/auth_service.dart';
import 'package:doom_breaker/services/storage_service.dart';
import 'package:doom_breaker/UI/pages/settings_page.dart';
import 'package:doom_breaker/UI/pages/onboarding/permission_guide_page.dart';
import 'package:doom_breaker/services/platform_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:doom_breaker/UI/Widgets/app_text.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static const String name = '/welcome';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with WidgetsBindingObserver {
  final PlatformService _platform = PlatformService();
  String? _userName;
  bool _isAllGranted = false;
  bool _showSuccess = false;
  bool _isLoading = true;
  bool _showWarningText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _checkPermissions();

    // Show warning text after 2 seconds if permissions not granted
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isAllGranted) {
        setState(() => _showWarningText = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only check if this page is actually visible
      if (ModalRoute.of(context)?.isCurrent == true) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _checkPermissions();
          }
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    await storage.init();

    final profile = storage.getUserProfile();
    if (mounted) {
      setState(() {
        _userName = profile?.displayName;
      });
    }
  }

  Future<void> _checkPermissions() async {
    final permissions = await _platform.checkAllPermissions();
    final allGranted = !permissions.containsValue(false);

    if (mounted) {
      if (!allGranted) {
        // Permissions missing
        setState(() {
          _isAllGranted = false;
          _showSuccess = false;
          _isLoading = false;
        });
      } else {
        // All granted
        if (!_isAllGranted) {
          // Changed from not granted to granted - show success!
          setState(() {
            _isAllGranted = true;
            _showSuccess = true;
            _isLoading = false;
          });

          // Hide success message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _showSuccess = false);
            }
          });
        } else {
          // Already granted previously
          setState(() {
            _isAllGranted = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _userName ?? user?.email?.split('@').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doom Breaker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(SettingsPage.name).then((_) {
                if (mounted) _checkPermissions();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                    Icons.spa_rounded,
                    size: 64,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 32),
                AppText.hero(
                  'Welcome Back,\n$displayName',
                  textAlign: TextAlign.center,
                  color: const Color(0xFF0D47A1),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: AppText.bodySmall(
                    'Your focus journey continues.',
                    color: const Color(0xFF546E7A),
                  ),
                ),
                const SizedBox(height: 64),
                OutlinedButton.icon(
                  onPressed: () async {
                    await StorageService().clearAll();
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        LoginPage.name,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: BorderSide(
                      color: const Color(0xFFD32F2F).withOpacity(0.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildPermissionFab(),
    );
  }

  Widget? _buildPermissionFab() {
    if (_isLoading) return null;

    // If all granted and success shown
    if (_isAllGranted) {
      if (_showSuccess) {
        return FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: const Color(0xFF1976D2),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          elevation: 4,
          label: const Text(
            "You're all set!",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        );
      }
      return null; // Hide completely when all granted
    }

    // Warning state
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showWarningText)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              "Permissions missing!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(PermissionGuidePage.name).then((_) {
              if (mounted) _checkPermissions();
            });
          },
          backgroundColor: const Color(0xFFD32F2F),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.gpp_maybe_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}
