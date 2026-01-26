import 'package:doom_breaker/UI/pages/login_page.dart';
import 'package:doom_breaker/UI/pages/signup_page.dart';
import 'package:doom_breaker/UI/pages/onboarding/onboarding_page.dart';
import 'package:doom_breaker/UI/pages/onboarding/permission_guide_page.dart';
import 'package:doom_breaker/UI/pages/welcome_page.dart';
import 'package:doom_breaker/UI/pages/settings_page.dart';
import 'package:doom_breaker/services/auth_service.dart';
import 'package:doom_breaker/services/storage_service.dart';
import 'package:doom_breaker/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoomBreakerApp extends StatelessWidget {
  const DoomBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doom Breaker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Forest Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF66BB6A), // Fresh Green
          surface: const Color(0xFFF5F9F6), // Minty White Background
          error: const Color(0xFFD32F2F),
          background: const Color(0xFFF5F9F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F9F6),
          foregroundColor: Color(0xFF1B5E20), // Dark Green text
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        LoginPage.name: (_) => const LoginPage(),
        SignupPage.name: (_) => const SignupPage(),
        OnboardingPage.name: (_) => const OnboardingPage(),
        PermissionGuidePage.name: (_) => const PermissionGuidePage(),
        WelcomePage.name: (_) => const WelcomePage(),
        SettingsPage.name: (_) => const SettingsPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data?.session != null) {
          final user = snapshot.data!.session!.user;
          return FutureBuilder(
            future: _loadUserProfile(user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final hasProfile = profileSnapshot.data ?? false;

              if (!hasProfile) {
                // No profile in cloud, show onboarding
                return const OnboardingPage();
              }

              // Profile exists (loaded from cloud and saved locally)
              return const WelcomePage();
            },
          );
        }

        return const LoginPage();
      },
    );
  }

  /// Loads user profile from Supabase and saves to local storage
  /// Returns true if profile exists, false otherwise
  Future<bool> _loadUserProfile(String userId) async {
    try {
      final storage = StorageService();
      await storage.init();

      // Check local cache first
      final localProfile = storage.getUserProfile();
      if (localProfile != null && localProfile.userId == userId) {
        // Local profile exists and matches current user
        return true;
      }

      // Try to fetch from Supabase
      final syncService = SyncService();
      syncService.setUserId(userId);
      final cloudProfile = await syncService.fetchUserProfile(userId);

      if (cloudProfile != null) {
        // Profile exists in cloud, save to local storage
        await storage.saveUserProfile(cloudProfile);
        await storage.setOnboardingComplete(true);
        return true;
      }

      // No profile found anywhere
      return false;
    } catch (e) {
      // Error fetching profile, assume no profile exists
      return false;
    }
  }
}
