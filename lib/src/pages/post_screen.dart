import 'package:flutter/material.dart';
import 'package:linkup/src/pages/home.dart';
import 'package:linkup/src/widgets/header.dart';
import 'package:linkup/src/widgets/post.dart';
import 'package:linkup/src/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String? userId;
  final String? postId;

  PostScreen({this.userId, this.postId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: postsRef.doc(userId).collection('usersPosts').doc(postId).get(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          Post post = Post.fromDocument(snapshot.data);
          return Center(
            child: Scaffold( 
              appBar: header(titleText: post.description),
              body: ListView(
                children: [
                  Container(
                    child: post,
                  ),
                ],
              ),
            ),
          );
        });
  }
}
