import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String currentUserId = currentUser?.id;
  bool isLoading = false;
  int postCount = 0;
  List<Post> postList = [];
  String postOrientation =
      "gridView"; // sets the default view to grid until toggled

  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    print("Profile id ${widget.profileId}");

    QuerySnapshot snapshot = await postDbRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timeStamp', descending: true)
        .get();

    setState(() {
      isLoading = false;
      //get the number of posts for a user
      postCount = snapshot.docs.length;
      //get all posts and deserialize it
      postList = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
      print(postList.length);
    });
  }

  Column buildLikesCounter(int likes, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Column(
              children: [
                Text(
                  likes.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4.0),
                  child: Text(label,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        )
      ],
    );
  }

  buildButton({String label, Function function}) {
    return RaisedButton.icon(
      color: Colors.blue,
      onPressed: function,
      icon: Icon(
        Icons.edit,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  onEditProfileClicked() {
    //goto edit profile page
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EditProfile(currentUserId: currentUserId);
    }));
  }

  buildEditProfileButton() {
    bool isCurrentUser = currentUserId == widget.profileId;
    if (isCurrentUser) {
      return buildButton(label: "Edit Profile", function: onEditProfileClicked);
    }
  }

  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
      future: usersDbRef.doc(widget.profileId).get(),
      builder: (context, snapShot) {
        if (!snapShot.hasData) {
          return circularProgress();
        }

        Users users = Users.fromDocument(snapShot.data);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      backgroundImage:
                          CachedNetworkImageProvider(users.photoUrl),
                      radius: 32.0,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            buildLikesCounter(postCount, "Posts"),
                            buildLikesCounter(1, "Followers"),
                            buildLikesCounter(2, "Following"),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildEditProfileButton(),
                          ],
                        )
                      ],
                    ),
                    flex: 1,
                  )
                ],
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${users.displayName.toUpperCase()}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  )),
              Container(
                  margin: EdgeInsets.only(top: 4.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${users.bio}",
                    style: TextStyle(fontSize: 16.0),
                    textAlign: TextAlign.start,
                  )),
            ],
          ),
        );
      },
    );
  }

  buildOrientationState(String type) {
    setState(() {
      this.postOrientation = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Profile"),
      body: ListView(
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        children: [
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildToggleOrientation(),
          Divider(),
          buildPostsPage(context),
        ],
      ),
    );
  }

  buildPostsPage(context) {
    final orientation = MediaQuery.of(context).orientation;

    if (isLoading) {
      return circularProgress();
    }else if(postList.isEmpty){
      //display a splash for no content
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/images/no_content.svg",
              height: orientation == Orientation.portrait ? 150.0 : 100,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "No content available",
                style: TextStyle(color: Colors.black, fontSize: 14.0),
              ),
            )
          ],
        ),
      );

    }

    if (postOrientation == "gridView") {
      List<GridTile> gridTileList = [];
      postList.forEach((element) {
        gridTileList.add(GridTile(
          child: PostTile(
            post: element,
          ),
        ));
      });

      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 1.0,
        physics: NeverScrollableScrollPhysics(),
        children: gridTileList,
      );
    } else if (postOrientation == "listView") {
      return Column(
        children: postList,
      );
    }
  }

  buildToggleOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          //changes the color of the icon based on the type selected
          color: postOrientation == "gridView" ? Colors.green : Colors.grey,
            icon: Icon(Icons.grid_on),
            onPressed: () => buildOrientationState("gridView")),
        IconButton(
        color: postOrientation == "listView" ? Colors.green : Colors.grey,
            icon: Icon(Icons.list),
            onPressed: () => buildOrientationState("listView"))
      ],
    );
  }
}
