import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Sign out immediately to prevent auto-login
      await _supabase.auth.signOut();

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google (using Supabase OAuth)
  Future<bool> signInWithGoogle() async {
    try {
      // Use Supabase's native Google OAuth
      // This will open a browser/webview for Google sign-in
      final bool result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );

      return result;
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_supabase.auth.signOut(), _googleSignIn.signOut()]);
  }

  // Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    switch (e.message) {
      case String msg when msg.contains('rate limit'):
        return 'Too many attempts. Please wait a few minutes and try again.';
      case String msg when msg.contains('Invalid login credentials'):
        return 'Invalid email or password. Please try again.';
      case String msg when msg.contains('Email not confirmed'):
        return 'Please verify your email address before signing in.';
      case String msg when msg.contains('User already registered'):
        return 'This email is already registered. Please sign in instead.';
      case String msg when msg.contains('Password should be at least'):
        return 'Password is too weak. Please use a stronger password.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
