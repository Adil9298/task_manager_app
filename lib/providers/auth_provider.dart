import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _authController;
  final SessionService _sessionService;

  AuthProvider({
    AuthController? authController,
    SessionService? sessionService,
  })  : _authController =
      authController ?? AuthController(),
        _sessionService =
            sessionService ?? SessionService();

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  UserModel? _currentUser;

  bool _isLoading = false;

  bool _isInitialized = false;

  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  UserModel? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  bool get isLoggedIn => _currentUser != null;

  bool get isGuest =>
      _currentUser?.isGuest ?? false;

  bool get isGoogleUser =>
      _currentUser != null &&
          !_currentUser!.isGuest;

  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN IN
  // ---------------------------------------------------------------------------

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user =
      await _authController.signInWithGoogle();

      if (user == null) {
        _errorMessage =
        'Google sign-in was cancelled.';

        return false;
      }

      final googleUser = user.copyWith(
        isGuest: false,
      );

      _currentUser = googleUser;

      // Save session locally.
      await _sessionService.saveSession(
        uid: googleUser.uid,
        isGuest: false,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // GUEST SIGN IN
  // ---------------------------------------------------------------------------

  Future<bool> signInAsGuest() async {
    _setLoading(true);
    _clearError();

    try {
      final user =
      await _authController.signInAsGuest();

      if (user == null) {
        _errorMessage =
        'Unable to start guest session.';

        return false;
      }

      final guestUser = user.copyWith(
        isGuest: true,
      );

      _currentUser = guestUser;

      // Save guest session locally.
      await _sessionService.saveSession(
        uid: guestUser.uid,
        isGuest: true,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // CHECK LOGIN
  // ---------------------------------------------------------------------------

  Future<void> checkLogin() async {
    _setLoading(true);
    _clearError();

    try {
      final user =
      await _authController.getCurrentUser();

      if (user == null) {
        _currentUser = null;

        await _sessionService.clearSession();

        return;
      }

      _currentUser = user;

      // Refresh the local session cache.
      await _sessionService.saveSession(
        uid: user.uid,
        isGuest: user.isGuest,
      );
    } catch (e) {
      _currentUser = null;

      _errorMessage =
          _cleanErrorMessage(e);
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authController.signOut();

      _currentUser = null;

      // Always clear the cached session.
      await _sessionService.clearSession();

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // CLEAR ERROR
  // ---------------------------------------------------------------------------

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanErrorMessage(
      Object error,
      ) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    super.dispose();
  }
}