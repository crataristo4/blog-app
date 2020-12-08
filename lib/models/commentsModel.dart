import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModel {
  String userName;
  String postId;
  String ownerId;
  String userPhotoUrl;
  String comment;
  Timestamp timeStamp;

  CommentsModel(
      {this.userName,
        this.postId,
        this.ownerId,
        this.userPhotoUrl,
        this.comment,
        this.timeStamp});

  factory CommentsModel.fromDocumentSnapShot(DocumentSnapshot snapshot) {
    return CommentsModel(
        userName: snapshot["userName"],
        postId: snapshot["postId"],
        ownerId: snapshot["ownerId"],
        userPhotoUrl: snapshot["userPhotoUrl"],
        comment: snapshot["comment"],
        timeStamp: snapshot["timeStamp"]);
  }
}