import 'package:firebase_auth/firebase_auth.dart' as firebase;

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int requestsUsed;
  final int requestsLimit;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.requestsUsed = 0,
    this.requestsLimit = 50,
  });

  factory User.fromFirebaseUser(firebase.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      requestsUsed: 0,
      requestsLimit: 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'requestsUsed': requestsUsed,
      'requestsLimit': requestsLimit,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      requestsUsed: json['requestsUsed'],
      requestsLimit: json['requestsLimit'],
    );
  }
}
