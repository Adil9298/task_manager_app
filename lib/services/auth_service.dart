import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:task_manager_app/services/session_service.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
  GoogleSignIn();

  final SessionService _sessionService =
  SessionService();

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN IN
  // ---------------------------------------------------------------------------

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      // User cancelled the Google sign-in dialog.
      if (googleUser == null) {
        return null;
      }

      // Get Google authentication credentials.
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create Firebase credential.
      final credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase.
      final UserCredential userCredential =
      await _auth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Unable to retrieve authenticated user.',
        );
      }

      // Firebase is the source of truth for guest status.
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        isGuest: user.isAnonymous,
      );

      // Save/update the user document.
      await _saveUserToFirestore(
        userModel,
      );

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        e.message ??
            'Google authentication failed.',
      );
    } catch (e) {
      // Don't wrap our own meaningful exceptions unnecessarily.
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Google Sign-In failed.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GUEST SIGN IN
  // ---------------------------------------------------------------------------

  Future<UserModel?> signInAsGuest() async {
    try {
      final guestId =
      await _sessionService.getOrCreateGuestId();

      return UserModel(
        uid: guestId,
        name: 'Guest User',
        email: '',
        photoUrl: null,
        isGuest: true,
      );
    } catch (e) {
      throw Exception(
        'Unable to continue as guest: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE USER TO FIRESTORE
  // ---------------------------------------------------------------------------

  Future<void> _saveUserToFirestore(
      UserModel user,
      ) async {
    final docRef =
    _firestore
        .collection('users')
        .doc(user.uid);

    final snapshot =
    await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'isGuest': user.isGuest,
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      return;
    }

    // Existing Google user.
    await docRef.set(
      {
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'isGuest': user.isGuest,
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CURRENT USER
  // ---------------------------------------------------------------------------

  Future<UserModel?> getCurrentUser() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    return UserModel(
      uid: user.uid,
      name: user.isAnonymous
          ? 'Guest User'
          : user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      isGuest: user.isAnonymous,
    );
  }

  // ---------------------------------------------------------------------------
  // AUTH STATE CHANGES
  // ---------------------------------------------------------------------------

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out failure shouldn't prevent
      // Firebase sign-out.
    }

    await _auth.signOut();
  }
}