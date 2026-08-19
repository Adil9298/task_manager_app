import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService;

  AuthController({
    AuthService? authService,
  }) : _authService =
      authService ?? AuthService();

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN IN
  // ---------------------------------------------------------------------------

  Future<UserModel?> signInWithGoogle() async {
    return await _authService
        .signInWithGoogle();
  }

  // ---------------------------------------------------------------------------
  // GUEST SIGN IN
  // ---------------------------------------------------------------------------

  Future<UserModel?> signInAsGuest() async {
    return await _authService
        .signInAsGuest();
  }

  // ---------------------------------------------------------------------------
  // GET CURRENT USER
  // ---------------------------------------------------------------------------

  Future<UserModel?> getCurrentUser() async {
    return await _authService
        .getCurrentUser();
  }

  // ---------------------------------------------------------------------------
  // AUTH STATE
  // ---------------------------------------------------------------------------

  Stream<User?> authStateChanges() {
    return _authService
        .authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await _authService.signOut();
  }
}