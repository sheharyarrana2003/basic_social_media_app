import 'package:basic_social_media_app/components/button.dart';
import 'package:basic_social_media_app/components/comment.dart';
import 'package:basic_social_media_app/components/comment_button.dart';
import 'package:basic_social_media_app/components/delete_button.dart';
import 'package:basic_social_media_app/components/follow_button.dart';
import 'package:basic_social_media_app/components/like_button.dart';
import 'package:basic_social_media_app/helper/helper_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final String message;
  final String user;
  final String postId;
  final List<String> likes;
  final String time;
  final String userEmail;
  final String imgUri;
  const Post(
      {super.key,
      required this.message,
      required this.user,
      required this.postId,
      required this.likes,
      required this.time,
      required bool isFollowing,
      required Future<Null> Function() onFollowToggle,
      required this.userEmail,
      required this.imgUri});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final userCollections = FirebaseFirestore.instance.collection("Users");
  int totalComments = 0;
  bool isLiked = false;
  bool isFollowing =
      false; // Track if the current user is following the post's user
  final _commentController = TextEditingController();
  String userName = "";

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
    // Listen for changes in the comments collection to update totalComments
    FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.postId)
        .collection("Comments")
        .snapshots()
        .listen((snapshot) {
      setState(() {
        totalComments = snapshot.docs.length;
      });
    });
    checkFollowingStatus(); // Check if the current user is following the post's user
  }

  void checkFollowingStatus() async {
    DocumentSnapshot currentUserDoc =
        await userCollections.doc(currentUser.email).get();
    List<dynamic> followingList = currentUserDoc['following'] ?? [];
    userName = currentUserDoc["username"];

    setState(() {
      isFollowing = followingList.contains(widget.userEmail);
    });
  }

  void toggleFollow() async {
    final String userToFollow = widget.userEmail;

    if (userToFollow != currentUser.email) {
      // Get the document references for both users
      final DocumentReference userToFollowRef =
          userCollections.doc(userToFollow);
      final DocumentReference currentUserRef =
          userCollections.doc(currentUser.email);

      if (isFollowing) {
        // Unfollow the user
        await userToFollowRef.update({
          "followers": FieldValue.arrayRemove([currentUser.email])
        });
        await currentUserRef.update({
          "following": FieldValue.arrayRemove([userToFollow])
        });
      } else {
        // Follow the user
        await userToFollowRef.update({
          "followers": FieldValue.arrayUnion([currentUser.email])
        });
        await currentUserRef.update({
          "following": FieldValue.arrayUnion([userToFollow])
        });
      }

      setState(() {
        isFollowing = !isFollowing;
      });
    }
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    DocumentReference postRef =
        FirebaseFirestore.instance.collection("User Posts").doc(widget.postId);
    if (isLiked) {
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email])
      });
    } else {
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email])
      });
    }
  }

  void addComment(String commentText) {
    if (commentText.isNotEmpty) {
      FirebaseFirestore.instance
          .collection("User Posts")
          .doc(widget.postId)
          .collection("Comments")
          .add({
        "CommentText": commentText,
        "CommentBy": widget.user,
        "CommentTime": Timestamp.now(),
      }).then((_) {
        _commentController.clear();
      });
    }
  }

  void showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(hintText: "Write a comment.. "),
                  ),
                  SizedBox(height: 10),
                  BuildButton(
                      onTap: () => addComment(_commentController.text),
                      text: "Comment"),
                  SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("User Posts")
                        .doc(widget.postId)
                        .collection("Comments")
                        .orderBy("CommentTime", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: snapshot.data!.docs.map((doc) {
                          final commentData =
                              doc.data() as Map<String, dynamic>;
                          return Comment(
                              user: commentData["CommentBy"],
                              text: commentData["CommentText"],
                              time: formatDate(commentData["CommentTime"]));
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmation"),
        content: Text("Are you sure to delete post? "),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel")),
          TextButton(
              onPressed: () async {
                final commentDocs = await FirebaseFirestore.instance
                    .collection("User Posts")
                    .doc(widget.postId)
                    .collection("Comments")
                    .get();
                for (var doc in commentDocs.docs) {
                  await FirebaseFirestore.instance
                      .collection("User Posts")
                      .doc(widget.postId)
                      .collection("Comments")
                      .doc(doc.id)
                      .delete();
                }
                FirebaseFirestore.instance
                    .collection("User Posts")
                    .doc(widget.postId)
                    .delete()
                    .then((value) => print("post deleted"))
                    .catchError(
                        (error) => print("Failed to delete post: $error"));
                Navigator.pop(context);
              },
              child: Text("Delete")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(left: 20, right: 20, top: 20),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.imgUri),
                    radius: 20,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.user,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (widget.userEmail != currentUser.email)
                FollowButton(
                  isFollowing: isFollowing,
                  onTap: toggleFollow,
                ),
              if (widget.userEmail == currentUser.email)
                DeleteButton(onTap: deletePost),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'lib/Images/pic.jpg',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(widget.message),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      LikeButton(isLiked: isLiked, onTap: toggleLike),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        widget.likes.length.toString(),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      CommentButton(onTap: showCommentSheet),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        totalComments.toString(),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                widget.time,
                style: TextStyle(fontSize: 12),
              )
            ],
          ),
        ],
      ),
    );
  }
}
