import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/constants/AppConstants.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:fluttershare/pages/edit_profiles.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn =  GoogleSignIn();
final _auth = FirebaseAuth.instance;
final CollectionReference usersDbRef =
    FirebaseFirestore.instance.collection('users');
final CollectionReference postDbRef =
    FirebaseFirestore.instance.collection('posts');
final CollectionReference commentsRef = FirebaseFirestore.instance.collection("comments");
final firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;
final DateTime timeStamp = DateTime.now();
Users currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  @override
  void initState() {
    super.initState();

    pageController = PageController();
    _googleSignIn.onCurrentUserChanged.listen((event) {
      checkSignIn(event);
    }, onError: (onError) {
      print("Error signing in:  $onError");
    });

    //sign in silently if user has already logged in
    _googleSignIn
        .signInSilently(suppressErrors: true)
        .then((event) => {checkSignIn(event)})
        .catchError((onError) {
      print("Error signing in:  $onError");
    });
  }

  //check if user is signed in
  checkSignIn(GoogleSignInAccount event) {
    if (event != null) {
      createUsersDb();
      print("User signed in :: $event");
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  //log user in using google sign in
  Future<String> login() async {
    await Firebase.initializeApp();

    final GoogleSignInAccount googleSignInAccount =
        await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user;

    if (user != null) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final User currentUser = _auth.currentUser;
      assert(user.uid == currentUser.uid);

      print('signInWithGoogle succeeded: $user');

      return '$user';
    }

    return null;
  }


  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  //log user out
  logout() {
    _googleSignIn.signOut();
  }

  //create database for users
  createUsersDb() async {
    final GoogleSignInAccount user = _googleSignIn.currentUser;
    DocumentSnapshot docSnapShot = await usersDbRef.doc(user.id).get();

    //check if user exits , if not go to create account page
    if (!docSnapShot.exists) {
      String userName = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

//insert into the database users details
    await  usersDbRef.doc(user.id).set({
        "id": user.id,
        "userName": userName,
        "displayName": user.displayName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "timeStamp": timeStamp,
        "bio": ""
      });

      docSnapShot = await usersDbRef.doc(user.id).get();
    }
    setState(() {
      currentUser = Users.fromDocument(docSnapShot);
    });
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          // Timeline(),

          RaisedButton(
            onPressed: logout,
            child: Text("log out"),
          ),
          ActivityFeedItem(),
          Upload(user: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
      ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.notifications,
          )),
          BottomNavigationBarItem(
              icon: Icon(Icons.photo_camera, size: AppConstants.margin32)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
        onTap: onTap,
        currentIndex: pageIndex,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
              //Colors.teal,
              // Colors.purple
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.fltShare,
              style: TextStyle(
                  fontFamily: "Signatra",
                  fontSize: AppConstants.fontSizeBig,
                  color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                login().then((value) => {
                      if (value != null) {buildAuthScreen()}
                    });
              },
              child: Container(
                width: AppConstants.containerWidth,
                height: AppConstants.containerHeight,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                            "assets/images/google_signin_button.png"),
                        fit: BoxFit.cover)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
