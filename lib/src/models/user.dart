import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String? email;
  final String photoUrl;
  final String displayName;
  final String bio;

  User(
      {required this.id,
      required this.username,
      this.email,
      required this.photoUrl,
      required this.displayName,
      required this.bio});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
    );
  }
}
