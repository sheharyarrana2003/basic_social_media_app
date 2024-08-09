import 'package:basic_social_media_app/components/post.dart';
import 'package:basic_social_media_app/components/text_field.dart';
import 'package:basic_social_media_app/helper/helper_methods.dart';
import 'package:basic_social_media_app/helper/theme_changer.dart';
import 'package:basic_social_media_app/pages/add_post.dart';
import 'package:basic_social_media_app/pages/profile_page.dart';
import 'package:basic_social_media_app/pages/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final userCollections = FirebaseFirestore.instance.collection("Users");
  final currentUser = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  final textController = TextEditingController();
  final List<String> _pageTitles = ['Home', 'Search', 'Post', 'Profile'];

  Future<void> postMessage() async {
    if (textController.text.trim().isNotEmpty) {
      DocumentSnapshot userDoc =
          await userCollections.doc(currentUser.email).get();
      String username = userDoc.get("username");
      String imageUri = userDoc.get("image");
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text.trim(),
        'TimeStamp': Timestamp.now(),
        'Likes': [],
        'username': username,
        'image': imageUri,
        'postImage': "",
      });
    } else {
      return null;
    }
    setState(() {
      textController.clear();
    });
  }

  Future<bool> isFollowing(String userEmail) async {
    final userDoc = await userCollections.doc(currentUser.email).get();
    final following = List<String>.from(userDoc["following"] ?? []);
    return following.contains(userEmail);
  }

  Future<void> toggleFollow(String userEmail) async {
    final userDoc = await userCollections.doc(currentUser.email).get();
    final following = List<String>.from(userDoc["following"] ?? []);

    if (following.contains(userEmail)) {
      following.remove(userEmail);
    } else {
      following.add(userEmail);
    }

    await userCollections
        .doc(currentUser.email)
        .update({"following": following});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: GNav(
          gap: 8,
          tabBackgroundColor: Colors.grey.shade100,
          activeColor: Colors.blue,
          padding: const EdgeInsets.all(16),
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: const [
            GButton(
              icon: Icons.home,
              text: "Home",
            ),
            GButton(
              icon: Icons.search,
              text: "Search",
            ),
            GButton(
              icon: Icons.add,
              text: "Post",
            ),
            GButton(icon: Icons.person, text: "Profile"),
          ],
        ),
      ),
      appBar: AppBar(
        title: Center(
          child: Text(
            _pageTitles[_selectedIndex],
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return IconButton(
                  icon: Icon(
                    themeNotifier.isLightMode
                        ? Icons.wb_sunny
                        : Icons.nights_stay,
                  ),
                  onPressed: () {
                    themeNotifier.toggleTheme();
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return IndexedStack(
              index: _selectedIndex,
              children: [
                buildHomePage(),
                SearchPage(),
                const AddPost(),
                const ProfilePage(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildHomePage() {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: BuildTextField(
                    controller: textController,
                    hint: "Write Something..",
                    obscureText: false,
                  ),
                ),
                IconButton(
                  onPressed: postMessage,
                  icon: const Icon(Icons.arrow_circle_up),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("User Posts")
                  .orderBy("TimeStamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: userCollections.doc(currentUser.email).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasData) {
                        final following = List<String>.from(
                            userSnapshot.data!["following"] ?? []);
                        final followers = List<String>.from(
                            userSnapshot.data!["followers"] ?? []);
                        final showOwnPostsOnly =
                            following.isEmpty && followers.isEmpty;
                        final posts = snapshot.data!.docs.where((post) {
                          final isFollowingUser =
                              following.contains(post["UserEmail"]);
                          final isOwnPost =
                              post["UserEmail"] == currentUser.email;
                          return showOwnPostsOnly
                              ? isOwnPost
                              : isOwnPost || isFollowingUser;
                        }).toList();

                        return ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final isFollowingFuture =
                                isFollowing(post["UserEmail"]);

                            return FutureBuilder<bool>(
                              future: isFollowingFuture,
                              builder: (context, isFollowingSnapshot) {
                                if (isFollowingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center();
                                } else if (isFollowingSnapshot.hasError) {
                                  return Center(
                                    child: Text(
                                        "Error: ${isFollowingSnapshot.error}"),
                                  );
                                } else if (isFollowingSnapshot.hasData) {
                                  final isFollowing = isFollowingSnapshot.data!;

                                  return Post(
                                    message: post["Message"],
                                    user: post["username"],
                                    postId: post.id,
                                    likes:
                                        List<String>.from(post['Likes'] ?? []),
                                    time: formatDate(post["TimeStamp"]),
                                    onFollowToggle: () async {
                                      await toggleFollow(post["UserEmail"]);
                                      setState(() {});
                                    },
                                    isFollowing: isFollowing,
                                    userEmail: post["UserEmail"],
                                    imgUri: post["image"],
                                    postImage: post["postImage"],
                                  );
                                }
                                return Container();
                              },
                            );
                          },
                        );
                      } else if (userSnapshot.hasError) {
                        return Center(
                          child: Text("Error: ${userSnapshot.error}"),
                        );
                      }
                      return const Center();
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
