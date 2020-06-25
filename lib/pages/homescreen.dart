import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/main.dart';
import 'package:chat/pages/const.dart';
import 'package:chat/pages/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat.dart';
import 'loading.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;

  const HomeScreen({Key key, @required this.currentUserId}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid ? showNotification(message['notification']) : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance.collection('users').document(widget.currentUserId).updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'com.example.chat' : 'com.duytq.flutterchatdemo',
      'Flutter Chat',
      'Message received',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print(message);
    //    print(message['body'].toString());
    //    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(
        0, message['title'].toString(), message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));

    //    await flutterLocalNotificationsPlugin.show(
    //        0, 'plain title', 'plain body', platformChannelSpecifics,
    //        payload: 'item x');
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SimpleDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            contentPadding: EdgeInsets.all(0.0),
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xFFFF8556),
                      Color(0xFFF54B64),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    color: currentUserMessageColor,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0))),
                height: 100.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => App()), (Route<dynamic> route) => false);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: new Text(
          "Chat",
          style: GoogleFonts.roboto(fontSize: 40),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFFF1F1F1),
            child: Icon(Icons.add, color: Colors.grey),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            icon: Icon(Icons.more_vert, color: Colors.grey),
            onSelected: onItemMenuPress,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          new SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 30, right: 30),
                            child: Form(
                              child: TextFormField(
                                keyboardAppearance: Brightness.dark,
                                textAlign: TextAlign.center,
                                style: TextStyle(),
                                decoration: InputDecoration(
                                    hintText: "Search",
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: greyColor,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              separatorBuilder: (context, pos) {
                                return Divider(
                                  endIndent: 50,
                                  thickness: 0.4,
                                  indent: 20,
                                );
                              },
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.all(10.0),
                              itemBuilder: (context, index) => buildItem(context, snapshot.data.documents[index]),
                              itemCount: snapshot.data.documents.length,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  void configLocalNotification() {
    var initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document['id'] == widget.currentUserId) {
      return Container();
    } else {
      return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Chat(
                        peerId: document.documentID,
                        peerAvatar: document['photoUrl'],
                        peerUserName: document["nickname"],
                      )));
        },
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Material(
                    child: document['photoUrl'] != null
                        ? Stack(
                            children: <Widget>[
                              new CircleAvatar(
                                maxRadius: 30,
                                minRadius: 20,
                                backgroundColor: Colors.black,
                                /* child: CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.0,
                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                              ),
                              width: 60.0,
                              height: 60.0,
                              padding: EdgeInsets.all(15.0),
                            ),
                            imageUrl: document['photoUrl'],
                            width: 60.0,
                            height: 60.0,
                            fit: BoxFit.cover,
                      ),*/
                                backgroundImage: NetworkImage(document['photoUrl'].toString()),
                              ),

                              // Notification bade -- Count number of unread messages
                              Positioned(
                                left: 40,
                                top: 0,
                                right: 0,
                                bottom: 42,
                                child: new Container(
                                  padding: EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                      color: Colors.blue[400],
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black.withOpacity(0.4), blurRadius: 10, spreadRadius: 0.5)
                                      ],
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: new Text(
                                        "1",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: greyColor,
                          ),
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          child: Text(
                            '${document['nickname']}',
                            style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        // Container(
                        //   child: Text(
                        //     'Status: ${document['aboutMe'] ?? 'Not available'}',
                        //     style: TextStyle(color: primaryColor),
                        //   ),
                        //   alignment: Alignment.centerLeft,
                        //   margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        // )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20.0),
                  ),
                ],
              ),
              Container(
                child: Text(
                  '1 hr ago',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
