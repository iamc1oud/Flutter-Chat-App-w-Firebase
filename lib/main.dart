import 'package:chat/pages/ChatMainPage.dart';
import 'package:chat/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:chat/pages/const.dart";

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: themeColor, scaffoldBackgroundColor: Colors.white),
      home: LoginScreen(title: "Chat"),
    );
  }
}
