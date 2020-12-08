import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String userName;
  final String location;
  final String description;
  final String url;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.userName,
    this.location,
    this.description,
    this.url,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      userName: doc['userName'],
      location: doc['location'],
      description: doc['description'],
      url: doc['url'],
      likes: doc['likes'],
    );
  }

  int getLikes(likes) {
    int countLikes = 0;
    if (likes == null) {
      return 0;
    }

    likes.values.forEach((val) {
      if (val == true) {
        countLikes += 1;
      }
    });

    return countLikes;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        userName: this.userName,
        location: this.location,
        description: this.description,
        url: this.url,
        likes: this.likes,
        likeCount: getLikes(this.likes),
      );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  final String userName;
  final String location;
  final String description;
  final String url;
  int likeCount;
  Map likes;
  bool isLiked;
  final String currentUserId = currentUser?.id;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.userName,
    this.location,
    this.description,
    this.url,
    this.likes,
    this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersDbRef.doc(widget.ownerId).get(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        Users users = Users.fromDocument(snapshot.data);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(users.photoUrl),
            radius: 16.0,
            backgroundColor: Colors.blue,
          ),
          title: GestureDetector(
            onTap: () => print("Name tapped"),
            child: Text(
              userName,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue,
              ),
              Text(
                location,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () => print("Delete pressed"),
          ),
        );
      },
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: onLikeClicked,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(url),
          /*showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),*/
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
              child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 28.0,
                  ),
                  onPressed: onLikeClicked),
            ),
            Container(
              //likes
              child: Text(
                "$likeCount likes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 8.0),
              child: IconButton(
                  icon: Icon(
                    Icons.chat,
                    color: Colors.blue,
                    size: 28.0,
                  ),
                  onPressed: () =>
                      navigateToCommentsPage(context, ownerId, postId, url)),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Text(
                  "$description",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }

  //method for liking post
  void onLikeClicked() {
    bool isPostLiked = likes[currentUserId] == true;

    //if post is liked  set isLiked to false , decrement like count and set value of the user liked to false
    if (isPostLiked) {
      //update the field in database
      postDbRef
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': false});
      setState(() {
        isLiked = false;
        likes[currentUserId] = false;
        likeCount -= 1;
      });
    }
    //if post is liked  set isLiked to true , increment like count and set value of the user liked to true
    else if (!isPostLiked) {
      //update the field in database
      postDbRef
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': true});
      setState(() {
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
        likeCount += 1;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }
}

//navigate to comments page
navigateToCommentsPage(
    BuildContext context, String ownerId, String postId, String url) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) {
    return Comments(
      ownerId: ownerId,
      postId: postId,
      url: url,
    );
  }));
}
