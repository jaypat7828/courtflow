import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;
  final _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      data: {'username': username.trim()},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Queues a confirmation email for the current user.
  /// Processed in batches by the Edge Function to stay under rate limits.
  Future<void> queueConfirmationEmail() async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('email_queue').insert({
      'user_id': user.id,
      'email': user.email,
      'type': 'email_confirmation',
      // Stagger sends: schedule 2 minutes after sign-up to avoid burst
      'scheduled_at': DateTime.now()
          .add(const Duration(minutes: 2))
          .toIso8601String(),
    });
  }
}
