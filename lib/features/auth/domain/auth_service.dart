import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/user/models/user.dart';
import 'package:what_can_i_make/features/user/data/user_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/features/user/models/user_limits.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final UserRepository _userRepository;
  final ErrorHandler _errorHandler;
  User? _currentUser;

  AuthService({
    required UserRepository userRepository,
    required ErrorHandler errorHandler,
  }) : _userRepository = userRepository,
       _errorHandler = errorHandler {
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
      return Left(AuthFailure('Sign in failed', null));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_getFriendlyErrorMessage(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
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
        _errorHandler.handleEither(
          await _userRepository.saveRequestLimit(
            _currentUser!.id,
            UserLimits.defaultRequestLimit,
          ),
        );
        _errorHandler.handleEither(
          await _userRepository.saveRequestUsage(
            _currentUser!.id,
            UserLimits.initialRequestCount,
          ),
        );
        notifyListeners();
        return Right(_currentUser!);
      }
      return Left(AuthFailure('Account creation failed', null));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_getFriendlyErrorMessage(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  Future<Either<Failure, Unit>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No user is signed in', null));
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      _currentUser = User.fromFirebaseUser(user);
      notifyListeners();
      return const Right(unit);
    } on Exception catch (e) {
      return Left(AuthFailure('Failed to update profile', e));
    }
  }

  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on firebase.FirebaseAuthException catch (e) {
      return Left(_getFriendlyErrorMessage(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
      return const Right(unit);
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  Failure _getFriendlyErrorMessage(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email', e);
      case 'wrong-password':
        return AuthFailure('Incorrect password', e);
      case 'email-already-in-use':
        return AuthFailure('Email is already in use', e);
      case 'weak-password':
        return AuthFailure('Password is too weak', e);
      case 'invalid-email':
        return AuthFailure('Invalid email format', e);
      case 'user-disabled':
        return AuthFailure('This account has been disabled', e);
      case 'operation-not-allowed':
        return AuthFailure('Operation not allowed', e);
      case 'too-many-requests':
        return AuthFailure('Too many attempts. Try again later', e);
      default:
        return AuthFailure('Authentication error', e);
    }
  }
}

class AuthFailure extends Failure {
  AuthFailure(super.message, super.error);
}
