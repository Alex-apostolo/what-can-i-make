import 'package:firebase_auth/firebase_auth.dart' as firebase;

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory User.fromFirebaseUser(firebase.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }

  User copyWith({String? displayName, String? photoUrl}) {
    return User(
      id: id,
      email: email,
      displayName: displayName ?? displayName,
      photoUrl: photoUrl ?? photoUrl,
    );
  }
}
