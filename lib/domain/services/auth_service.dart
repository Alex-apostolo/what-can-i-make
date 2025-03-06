import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import '../models/user.dart';
import 'package:dartz/dartz.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  User? _currentUser;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((firebase.User? firebaseUser) {
      if (firebaseUser != null) {
        _currentUser = User.fromFirebaseUser(firebaseUser);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _currentUser = User.fromFirebaseUser(userCredential.user!);
        notifyListeners();
        return Right(_currentUser!);
      }
      return Left(AuthFailure('Sign in failed'));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseExceptionToFailure(e));
    } catch (e) {
      return Left(
        AuthFailure('Unexpected error during sign in: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, User>> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _currentUser = User.fromFirebaseUser(userCredential.user!);
        notifyListeners();
        return Right(_currentUser!);
      }
      return Left(AuthFailure('Sign up failed'));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseExceptionToFailure(e));
    } catch (e) {
      return Left(
        AuthFailure('Unexpected error during sign up: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
      return Right(unit);
    } catch (e) {
      return Left(AuthFailure('Error signing out: ${e.toString()}'));
    }
  }

  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }

        _currentUser = User.fromFirebaseUser(user);
        notifyListeners();
        return Right(_currentUser!);
      }
      return Left(AuthFailure('No user is currently signed in'));
    } catch (e) {
      return Left(AuthFailure('Error updating profile: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return Right(unit);
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Error resetting password: ${e.toString()}'));
    }
  }

  Failure _mapFirebaseExceptionToFailure(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email');
      case 'wrong-password':
        return AuthFailure('Incorrect password');
      case 'user-disabled':
        return AuthFailure('This account has been disabled');
      case 'too-many-requests':
        return AuthFailure('Too many attempts. Please try again later');
      case 'email-already-in-use':
        return AuthFailure('This email is already in use');
      case 'weak-password':
        return AuthFailure('Password is too weak');
      case 'invalid-email':
        return AuthFailure('Invalid email address');
      default:
        return AuthFailure('Authentication error: ${e.message}');
    }
  }
}
