import 'package:flutter/material.dart';
import 'package:fluttershare/constants/AppConstants.dart';

circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: AppConstants.margin32),
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
    ),
  );
}

linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: AppConstants.margin16),
    child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.deepPurple)
    ),

  );
}
