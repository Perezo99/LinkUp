import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linkup/src/models/user.dart';
import 'package:linkup/src/pages/home.dart';
import 'package:linkup/src/pages/search.dart';
import 'package:linkup/src/widgets/header.dart';
import 'package:linkup/src/widgets/post.dart';
import 'package:linkup/src/widgets/progress.dart';

class Timeline extends StatefulWidget {
  final User? currentUser;

  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post>? posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followersRef
        .doc(currentUser!.id)
        .collection('usersFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser!.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();
    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts!.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts!);
    }
  }

  buildUsersToFollow() {
    return StreamBuilder(
        stream: usersRef
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          for (var doc in snapshot.data.docs) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = currentUser!.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            if (isAuthUser) {
              return Text('');
            } else if (isFollowingUser) {
              return Text('');
            } else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          }
          return Container(
            color: Colors.redAccent.withOpacity(0.2),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.red[900],
                        size: 30.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Users To Follow',
                        style:
                            TextStyle(color: Colors.red[900], fontSize: 30.0),
                      )
                    ],
                  ),
                ),
                Column(
                  children: userResults,
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(titleText: 'LINK UP'),
      body: RefreshIndicator(
        child: buildTimeline(),
        onRefresh: () => getTimeline(),
      ),
    );
  }
}
