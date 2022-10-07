import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:linkup/src/models/user.dart';
import 'package:linkup/src/pages/activity_feed.dart';
import 'package:linkup/src/pages/create_account.dart';
import 'package:linkup/src/pages/profile.dart';
import 'package:linkup/src/pages/search.dart';
import 'package:linkup/src/pages/timeline.dart';
import 'package:linkup/src/pages/upload.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersRef =
    FirebaseFirestore.instance.collection('users');
final CollectionReference postsRef =
    FirebaseFirestore.instance.collection('posts');
final storageRef = FirebaseStorage.instance.ref();
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activtyFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User? currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      pageController = PageController();
      // detects when user signed in
      googleSignIn.onCurrentUserChanged.listen((account) {
        handleSignIn(account);
      }, onError: (err) {
        // print('Error Signing in: $err');
      });

      // Reauthenticate User when app is opened
      googleSignIn
          .signInSilently(suppressErrors: false)
          .then(
            (account) => handleSignIn(account!),
          )
          .catchError((err) {
        // print('Error Signing in: $err');
      });
    });
  }

  handleSignIn(GoogleSignInAccount? account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      // print('somethings wrong: $account');
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    // if (Platform.isIOS) getiOSPermission();
    _firebaseMessaging.getToken().then((token) {
      // print('Firebase Messaging Token: $token\n');
      usersRef.doc(user!.id).update({"androidNotificationToken": token});
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // print('on message: $message\n');
      final String recipientId = (message as dynamic)['data']['recipient'];
      final String body = (message as dynamic)['notification']['body'];
      if (recipientId == user!.id) {
        // print('Notification Shown');

        SnackBar snackBar =
            SnackBar(content: Text(body, overflow: TextOverflow.ellipsis));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  createUserInFirestore() async {
    // check if user exists in user collection in db by id
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user!.id).get();

    if (!doc.exists) {
      // if user doesnt exist we take them to another page(create acct)
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // get username from create acct use it to create new user document
      usersRef.doc(user.id).set({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp
      });

      //make user their own follower
      await followersRef
          .doc(user.id)
          .collection('usersFollowers')
          .doc(user.id)
          .set({});

      doc = await usersRef.doc(user.id).get();
    }

    currentUser = User.fromDocument(doc);
    // print(currentUser);
    // print(currentUser!.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: [
          Timeline(currentUser: currentUser),
          // ElevatedButton(
          //   onPressed: logout,
          //   child: Text('Logout'),
          // ),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Colors.red,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
    // return ElevatedButton(
    //   onPressed: logout,
    //   child: Text('Logout'),
    // );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.red,
                Colors.black,
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Link Up',
              style: TextStyle(
                fontSize: 50.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
