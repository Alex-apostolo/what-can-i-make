import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/user.dart';
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
      return Left(AuthFailure('Account creation failed'));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseExceptionToFailure(e));
    } catch (e) {
      return Left(
        AuthFailure(
          'Unexpected error during account creation: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No user is signed in'));
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);

      _currentUser = User.fromFirebaseUser(user);
      notifyListeners();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseExceptionToFailure(e));
    } catch (e) {
      return Left(
        AuthFailure('Failed to send password reset email: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure('Failed to sign out: ${e.toString()}'));
    }
  }

  Failure _mapFirebaseExceptionToFailure(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email');
      case 'wrong-password':
        return AuthFailure('Incorrect password');
      case 'email-already-in-use':
        return AuthFailure('Email is already in use');
      case 'weak-password':
        return AuthFailure('Password is too weak');
      case 'invalid-email':
        return AuthFailure('Invalid email format');
      case 'user-disabled':
        return AuthFailure('This account has been disabled');
      case 'operation-not-allowed':
        return AuthFailure('Operation not allowed');
      case 'too-many-requests':
        return AuthFailure('Too many attempts. Try again later');
      default:
        return AuthFailure('Authentication error: ${e.message}');
    }
  }
}

class AuthFailure extends Failure {
  AuthFailure(String message) : super(message);
}
