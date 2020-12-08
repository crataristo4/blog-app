import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/constants/AppConstants.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String userName;
  final _formKey = GlobalKey<FormState>();
  final _snackBarKey = GlobalKey<ScaffoldState>();

  submit() {
    final _form = _formKey.currentState;

    if (_form.validate()) {
      _form.save();
      SnackBar snackBar = SnackBar(content: Text("Welcome $userName"));
      _snackBarKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, userName);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _snackBarKey,
      appBar: header(context, title: "Set up profile",removeBackButton: true),
      body: ListView(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppConstants.margin32),
                child: Center(
                    child: Text(
                  "Create a user name",
                  style: TextStyle(fontSize: AppConstants.font24),
                )),
              ),
              Padding(
                padding: EdgeInsets.all(AppConstants.margin8),
                child: Container(
                  child: Form(
                      key: _formKey,
                      autovalidate: true,
                      child: TextFormField(
                        validator: (value) {
                          if (value.trim().length < 3 || value.trim().isEmpty) {
                            return "Username is too short";
                          } else if (value.trim().length > 15) {
                            return "Username is too long";
                          } else if (value.contains(RegExp(r'^-?[0-9]+$'))) {
                            return "Invalid username";
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) => userName = val,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter your user name",
                            labelText: "Username",
                            labelStyle:
                                TextStyle(fontSize: AppConstants.margin8)),
                      )),
                ),
              ),
              GestureDetector(
                onTap: submit,
                child: Container(
                  width: 350.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.circular(AppConstants.margin8)),
                  child: Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                          color: Colors.white, fontSize: AppConstants.margin16),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
