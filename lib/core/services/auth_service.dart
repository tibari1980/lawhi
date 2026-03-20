import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  late final FirebaseAuth _auth;

  AuthService() {
    _auth = FirebaseAuth.instance;
    if (!kIsWeb) {
      _init();
    }
  }

  void _init() async {
    // Attempt sign in in background
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        // Silent fail
      }
    }
  }

  Stream<User?> get userChanges => kIsWeb ? Stream.value(null) : _auth.userChanges();
  User? get currentUser => kIsWeb ? null : _auth.currentUser;

  Future<UserCredential> signInAnonymously() async {
    if (kIsWeb) throw UnsupportedError('Firebase Auth disabled on Web');
    return await _auth.signInAnonymously();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userChanges;
});
