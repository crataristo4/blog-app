import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Users users;
  bool isLoading = false;
  bool isBioValid = true;
  bool isNameValid = true;

  TextEditingController userNameController = new TextEditingController();
  TextEditingController bioController = new TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  updateProfile() {
    setState(() {
      // check if the user name is empty or has more than three characters
      userNameController.text.trim().length < 3 ||
              userNameController.text.trim().isEmpty
          ? isNameValid = false
          : isNameValid = true;

      //  check if the bio is empty or has more than some specific length of characters

      bioController.text.trim().isEmpty ||
              bioController.text.length > 500 ||
              bioController.text.length < 3
          ? isBioValid = false
          : isBioValid = true;
    });

    //if true then update users records
    if (isBioValid && isNameValid) {
      usersDbRef.doc(widget.currentUserId).update(
          {"displayName": userNameController.text, "bio": bioController.text});

      //create a snack bar and show user if content is updated
      SnackBar snackBar = SnackBar(
        content: Text("Profile  updated successfully"),
      );

      //show the snack bar using the scaffold key created
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }else if(!isNameValid) {
      userNameController.clear();

    }else if(!isBioValid){
      bioController.clear();
    }
  }

  //returns the data from the cloud store and stores it in the users class
  FutureBuilder getUsers() {
    return FutureBuilder(
      future: usersDbRef.doc(widget.currentUserId).get(),
      builder: (context, snapShot) {
        if (!snapShot.hasData) {
          return circularProgress();
        }

        users = Users.fromDocument(snapShot.data);

        userNameController.text = users.displayName;
        bioController.text = users.bio;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildProfileImage(users),
              buildUserNameField(users),
              buildBioField(users),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    RaisedButton(
                      onPressed: updateProfile,
                      child: Text(
                        "Update profile",
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    FlatButton.icon(
                      color: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                      label: Text("Log out",
                          style:
                              TextStyle(color: Colors.white, fontSize: 24.0)),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  logout() async{

 //   await _googleSignIn.signOut();


  }


  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersDbRef.document(widget.currentUserId).get();
    users = Users.fromDocument(doc);
    userNameController.text = users.displayName;
    bioController.text = users.bio;
    setState(() {
      isLoading = false;
    });
  }

  //creates and returns the display name of the user
  Column buildUserNameField(Users users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            "User name",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0),
          child: TextField(
            controller: userNameController,
            decoration: InputDecoration(
                hintText: "Update your user name",
                errorText: isNameValid ? null : "invalid name"),
          ),
        ),
      ],
    );
  }

  //creates and returns the bio  of the user
  Column buildBioField(Users users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            "Bio",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0),
          child: TextField(
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: null,
            controller: bioController,
            decoration: InputDecoration(
                hintText: "Update your bio here",
                errorText: isBioValid ? null : "invalid bio"),
          ),
        ),
      ],
    );
  }

  //creates and returns the profile photo of the user
  Container buildProfileImage(Users users) {
    return Container(
      margin: EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: CircleAvatar(
        radius: 48,
        backgroundImage: CachedNetworkImageProvider(users.photoUrl),
      ),
    );
  }

  Scaffold buildEditProfilePage(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).accentColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Edit Profile"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.check, color: Colors.white), onPressed: () {})
        ],
      ),
      body: ListView(
        children: [Divider(), getUsers()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildEditProfilePage(context);
  }
}
