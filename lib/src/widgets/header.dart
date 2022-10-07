import 'package:flutter/material.dart';

AppBar header(
    {bool isAppTitle = false, String? titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: false,
    title: Text(
      isAppTitle ? 'LINK UP' : titleText!,
      style: TextStyle(
        color: Colors.white,
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Colors.red[900],
  );
}
