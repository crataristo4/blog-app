import 'dart:io';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as Im;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';


class Upload extends StatefulWidget {
  final Users user;

  Upload({this.user});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();
  TextEditingController captionController,
      locationController = TextEditingController();

  Container buildSplash() {
    final orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/upload.svg",
            height: orientation == Orientation.portrait ? 240.0 : 200,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FlatButton(
              color: Colors.white,
              padding: EdgeInsets.all(16.0),
              onPressed: () => selectImage(context),
              child: Text(
                "Upload Photo",
                style: TextStyle(color: Colors.black, fontSize: 14.0),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
            ),
          )
        ],
      ),
      decoration: BoxDecoration(color: Colors.blue),
    );
  }

  takePhotoWithCamera() async {
    Navigator.pop(context);

    File imageFile = (await ImagePicker.pickImage(source: ImageSource.camera));

    setState(() {
      this.file = imageFile;
    });
  }

  selectImageFromGallery() async {
    Navigator.pop(context);

    File mGalleryFile =
        await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      this.file = mGalleryFile;
    });
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  selectImage(BuildContext mContext) {
    return showDialog(
        barrierDismissible: true,
        context: mContext,
        builder: (context) {
          return SimpleDialog(
            title: Center(child: Text("Create Post")),
            children: [
              SimpleDialogOption(
                padding: const EdgeInsets.all(16.0),
                child: Text("Photo with camera"),
                onPressed: () => takePhotoWithCamera(),
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(16.0),
                child: Text("Photo from gallery"),
                onPressed: () => selectImageFromGallery(),
              ),
              Container(
                alignment: AlignmentDirectional.bottomEnd,
                child: SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.fromLTRB(0, 0, 24.0, 0),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red, fontSize: 16.0),
                  ),
                ),
              ),
            ],
          );
        });
  }

  //compress images before uploading
  compressImage() async {
    final tempDir = await getApplicationDocumentsDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());

    final compressedImage = File('$path/img_$postId.jpeg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));

    setState(() {
      file = compressedImage;
    });
  }

  Future<String> uploadImageToDb(imageFile) async {
    String downloadURL;
    Reference reference = FirebaseStorage.instance.ref("post_$postId.jpg");

    UploadTask uploadTask = reference.putFile(imageFile);

    uploadTask.whenComplete(() async {
      try {
        downloadURL = await reference.getDownloadURL();
      } catch (onError) {
        print(onError);
      }

      print('{$downloadURL}'"{$postId}""${widget.user.userName}");
    });

    return downloadURL;
  }

  createPost({String url, String caption, String location}) {
    postDbRef.doc(widget.user.id).collection("posts").doc(postId).set({
      "postId": postId,
      "ownerId": widget.user.id,
      "url": url,
      "userName": widget.user.displayName,
      "location": location,
      "description": caption,
      "timeStamp": timeStamp,
      "likes": {}
    });
/*
    //clear items in controller
    locationController.clear();
    captionController.clear();*/
/*
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });*/
  }

  submitImage() async {
    setState(() {
      isUploading = true;
    });

    await compressImage();
    String url = await uploadImageToDb(file);
    print(url);

    //create a post in database
  await createPost(
        url: url,
        caption: captionController.text,
        location: locationController.text);

    locationController.clear();
    captionController.clear();
    setState(() {
      isUploading =false;
      file=null;
      postId = Uuid().v4();
    });
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
  }

  getLocationFromUser() async {
    Position position = await Geolocator().getCurrentPosition
        (desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double lng = position.longitude;


    List<Placemark> placeMarkerList =
        await Geolocator().placemarkFromCoordinates(lat, lng);
    Placemark placeMark = placeMarkerList[0];
    String formattedAddress = "${placeMark.locality} , ${placeMark.country}";
    String completeAddress =
        '${placeMark.locality} , ${placeMark.country},${placeMark.administrativeArea} , ${placeMark.subAdministrativeArea},${placeMark.subThoroughfare} , ${placeMark.subLocality}';
    print(completeAddress);

    //DISplay results into the location text field
    locationController.text = formattedAddress;
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: Icon(Icons.arrow_back),
        title: Text(
          "Caption",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: FlatButton(
              onPressed: isUploading ? null : () => submitImage(),
              child: Text("Post",
                  style: TextStyle(color: Colors.white, fontSize: 24.0)),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          isUploading ? LinearProgressIndicator() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.cover, image: FileImage(file))),
                ),
              ),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
                //  backgroundImage: CachedNetworkImageProvider(widget.user.photoUrl),
                ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Caption photo", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.location_on),
            ),
            title: Container(
              width: MediaQuery.of(context).size.width,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: "Where was photo taken",
                    border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          Container(
            width: 250,
            height: 100,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () => getLocationFromUser(),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.blue,
              icon: Icon(Icons.gps_fixed),
              label: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Use current location",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplash() : buildUploadForm();
  }
}
