import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/constants/AppConstants.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Future<QuerySnapshot> userResults;
  TextEditingController controller = TextEditingController();

  clearSearch() {
    controller.clear();
  }

  handleSearch(String search) {
    Future<QuerySnapshot> users =
        usersDbRef.where("displayName", isGreaterThanOrEqualTo: search)
     .getDocuments();

    setState(() {
      userResults = users;
    });
  }

  AppBar buildSearchContent() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          prefixIcon: Icon(Icons.account_circle),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
          hintText: "Search",
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset("assets/images/search.svg",
                width: MediaQuery.of(context).size.width,
                height: orientation == Orientation.portrait ? 300.0 : 200),
            Center(
              child: Text(
                "Find users",
                style: TextStyle(
                    fontSize: AppConstants.margin64,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      builder: (context, snapShot) {
        //check results from search
        if (!snapShot.hasData) {
          return circularProgress();
        }

        List<UserResult> usersList = [];
        snapShot.data.documents.forEach((doc) {
          Users user = Users.fromDocument(doc);

         UserResult userResult = UserResult(user);
         usersList.add(userResult);
        });
        return ListView(
          children: usersList,
        );
      },
      future: userResults,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildSearchContent(),
      body: userResults == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final Users user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: [
          GestureDetector(
              onTap: () => print("object"),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                ),
                title: Text(
                  user.displayName,
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user.email,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
