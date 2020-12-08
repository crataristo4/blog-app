import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String id;
  final String userName;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;

  Users({this.id, this.userName, this.displayName, this.email, this.photoUrl,
      this.bio});

  factory Users.fromDocument(DocumentSnapshot documentSnapshot){
    return Users(
      id: documentSnapshot['id'],
      userName: documentSnapshot['userName'],
      displayName: documentSnapshot['displayName'],
      email: documentSnapshot['email'],
      photoUrl: documentSnapshot['photoUrl'],
      bio: documentSnapshot['bio'],


    );
  }
}
