import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linkup/src/pages/home.dart';
import 'package:linkup/src/pages/post_screen.dart';
import 'package:linkup/src/pages/profile.dart';
import 'package:linkup/src/widgets/header.dart';
import 'package:linkup/src/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activtyFeedRef
        .doc(currentUser!.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    List<ActivityFeedItem> feedItems = [];
    for (var doc in snapshot.docs) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    }
    return feedItems;
    // return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(titleText: 'Activity Feed'),
      body: Container(
        child: FutureBuilder(
            future: getActivityFeed(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              // print(snapshot.data[0]["username"]);
              if (!snapshot.hasData) {
                return circularProgress();
              }
              return ListView(
                children: snapshot.data,
              );
              // return ListView(
              //     children: (snapshot.data as List<dynamic>)
              //         .map((e) => ActivityFeedItem(
              //             username: "${e['username']}",
              //             userId: "${e['userId']}",
              //             type: "${e['type']}",
              //             mediaUrl: "${e['mediaUrl']}",
              //             postId: "${e['postId']}",
              //             userProfileImg: "${e['userProfileImg']}",
              //             commentData: "${e['commentData']}",
              //             timestamp: e['timestamp']))
              //         .toList());
            }),
      ),
    );
  }
}

Widget? mediaPreview;
String? activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String? username;
  final String? userId;
  final String? type;
  final String? mediaUrl;
  final String? postId;
  final String? userProfileImg;
  final String? commentData;
  final Timestamp? timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: CachedNetworkImageProvider(mediaUrl!),
                fit: BoxFit.cover,
              )),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = 'liked your Post';
    } else if (type == 'follow') {
      activityItemText = 'is following you';
    } else if (type == 'comment') {
      activityItemText = 'replied $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(
          profileId: profileId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.grey[300],
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $activityItemText'),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg!),
          ),
          subtitle: Text(
            timeago.format(timestamp!.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
