import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:linkup/src/models/user.dart';
import 'package:linkup/src/pages/comments.dart';
import 'package:linkup/src/pages/home.dart';
import 'package:linkup/src/pages/profile.dart';
import 'package:linkup/src/widgets/custom_image.dart';
import 'package:linkup/src/widgets/progress.dart';

class Post extends StatefulWidget {
  final String? postId;
  final String? ownerId;
  final String? username;
  final String? description;
  final String? mediaUrl;
  final dynamic likes;
  final String? location;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.description,
      this.mediaUrl,
      this.likes,
      this.location});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      location: doc['location'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    //if the key is set to true add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: this.getLikeCount(likes),
        location: this.location,
      );
}

class _PostState extends State<Post> {
  final String? currentUserId = currentUser?.id;
  final String? postId;
  final String? ownerId;
  final String? username;
  final String? location;
  final String? description;
  final String? mediaUrl;

  Map? likes;
  int likeCount;
  bool? isLiked;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.description,
    this.mediaUrl,
    this.likes,
    this.location,
    required this.likeCount,
  });

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

  buildPostHeader() {
    return FutureBuilder(
        future: usersRef.doc(ownerId).get(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
              onTap: () => showProfile(context, profileId: user.id),
              child: Text(
                user.username,
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(location.toString()),
            trailing: isPostOwner
                ? IconButton(
                    onPressed: () => handleDeletePost(context),
                    icon: Icon(Icons.more_vert))
                : Text(''),
          );
        });
  }

  handleDeletePost(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text('Remove this Post'),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                ),
              ),
            ],
          );
        });
  }

  deletePost() async {
    postsRef
        .doc(ownerId)
        .collection('usersPosts')
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image
    storageRef.child('post_$postId.jpg').delete();

    //delete all activity notification
    QuerySnapshot activityFeedSnapshot = await activtyFeedRef
        .doc(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .get();

    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete all commentss
    QuerySnapshot commentSnapshot =
        await commentsRef.doc(postId).collection('comments').get();
    commentSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes![currentUserId] == true;
    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('usersPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes![currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('usersPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes![currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    // add notification of liked post by other users to the activity feed
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activtyFeedRef.doc(ownerId).collection('feedItems').doc(postId).set({
        'type': 'like',
        'username': currentUser!.username,
        'userId': currentUser!.id,
        'userProfileImg': currentUser!.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activtyFeedRef
          .doc(ownerId)
          .collection('feedItems')
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(mediaUrl!),
          showHeart
              ? Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 200.0,
                )
              : Text(''),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 40.0,
                left: 20.0,
              ),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked! ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.red,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: 20.0,
              ),
            ),
            GestureDetector(
              onTap: () => showComments(context,
                  postId: postId, ownerId: ownerId, mediaUrl: mediaUrl),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$likeCount likes',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$username ' '',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(description!),
            ),
          ],
        ),
      ],
    );
  }

  showComments(BuildContext context,
      {String? postId, String? ownerId, String? mediaUrl}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Comments(
                postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl)));
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes![currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
