import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linkup/src/pages/home.dart';
import 'package:linkup/src/widgets/header.dart';
import 'package:linkup/src/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String? postId;
  final String? postOwnerId;
  final String? postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });
  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentsController = TextEditingController();
  final String? postId;
  final String? postOwnerId;
  final String? postMediaUrl;

  CommentsState({this.postId, this.postOwnerId, this.postMediaUrl});

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .doc(postId)
            .collection('comments')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.docs.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(children: comments);
        });
  }

  addComments() {
    commentsRef.doc(postId).collection('comments').add({
      'username': currentUser!.username,
      'comment': commentsController.text,
      'timestamp': timestamp,
      'avatarUrl': currentUser!.photoUrl,
      'userId': currentUser!.id,
    });
    bool isNotPostOwner = postOwnerId != currentUser!.id;
    if (isNotPostOwner) {
      activtyFeedRef.doc(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentsController.text,
        'timestamp': timestamp,
        'postId': postId,
        'userId': currentUser!.id,
        'username': currentUser!.username,
        'userProfileImg': currentUser!.photoUrl,
        'mediaUrl': postMediaUrl,
      });
    }

    commentsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(titleText: 'Comments'),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentsController,
              decoration: InputDecoration(labelText: 'Write a comment...'),
            ),
            trailing: OutlinedButton(
              onPressed: addComments,
              child: Text('Post'),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String? username;
  final String? userId;
  final String? avatarUrl;
  final String? comment;
  final Timestamp? timestamp;

  Comment(
      {this.username,
      this.userId,
      this.avatarUrl,
      this.comment,
      this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(comment!),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl!),
          ),
          subtitle: Text(timeago.format(timestamp!.toDate())),
        ),
      ],
    );
  }
}
