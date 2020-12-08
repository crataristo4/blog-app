import 'package:timeago/timeago.dart' as commentTime;
import 'package:fluttershare/models/commentsModel.dart';
import 'package:fluttershare/models/commentsModel.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';

class Comments extends StatefulWidget {
  final String ownerId, postId, url;

  Comments({this.ownerId, this.postId, this.url});

  @override
  CommentsState createState() =>
      CommentsState(this.ownerId, this.postId, this.url);
}

class CommentsState extends State<Comments> {
  final String ownerId, postId, url;

  CommentsState(this.ownerId, this.postId, this.url);

  String comment = "Comments";
  String commentHere = "Write your comments here";
  TextEditingController commentController = TextEditingController();

  buildComments() {
    return StreamBuilder(
      builder: (context, dataSnapShot) {
        if (!dataSnapShot.hasData) {
          return circularProgress();
        }

        /*  List<Comment> _commentsList = [];
      dataSnapShot.data.documents.forEach((doc) {
          _commentsList.add(Comment.fromDocument(doc));
        });*/

        List<CommentItems> _commentsItemsList = [];
        dataSnapShot.data.documents.forEach((doc) {
          CommentsModel commentsModel = CommentsModel.fromDocumentSnapShot(doc);

          CommentItems commentItems = CommentItems(commentsModel);

          _commentsItemsList.add(commentItems);
        });

        return ListView(
          children: _commentsItemsList,
        );
      },
      stream: commentsRef.doc(postId).collection(comment).snapshots(),
    );
  }

  addComment() {
    commentsRef.doc(postId).collection(comment).add({
      "userName": currentUser.userName,
      "userPhotoUrl": currentUser.photoUrl,
      "ownerId": currentUser.id,
      "timeStamp": timeStamp,
      "postId": postId,
      "comment": commentController.text
    });
    //clear comment controller after commenting
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: comment),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: commentHere),
            ),
            trailing: OutlineButton(
              borderSide: BorderSide.none,
              onPressed: () {
                addComment();
              },
              child: Text(
                comment.substring(0, 7),
                style: TextStyle(color: Colors.blue),
              ),
            ),
          )
        ],
      ),
    );
  }
}

//(optional with model class)
class Comment extends StatelessWidget {
  final String username;
  final String ownerId;
  final String userPhotoUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.ownerId,
    this.userPhotoUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      ownerId: doc['ownerId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      userPhotoUrl: doc['userPhotoUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userPhotoUrl),
            radius: 16.0,
          ),
          title: Text(username),
        ),
        Divider(),
      ],
    );
  }
}

//better with a separate model class
class CommentItems extends StatelessWidget {
  final CommentsModel commentsModel;

  CommentItems(this.commentsModel);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage:
                CachedNetworkImageProvider(commentsModel.userPhotoUrl),
            radius: 16.0,
          ),
          title: Text(commentsModel.userName),
          subtitle: Text(commentTime.format(commentsModel.timeStamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
