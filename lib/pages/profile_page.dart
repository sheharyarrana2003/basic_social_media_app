import 'dart:io';
import 'package:basic_social_media_app/components/follow_people.dart';
import 'package:basic_social_media_app/components/text_box.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final userCollections = FirebaseFirestore.instance.collection("Users");
  final currentUser = FirebaseAuth.instance.currentUser!;
  File? file;
  final ImagePicker imagePicker = ImagePicker();
  int followers = 0;
  int followings = 0;

  List<String> followingList = [];
  Map<String, bool> followingStatus = {};

  @override
  void initState() {
    super.initState();
    fetchFollowingList();
  }

  Future<void> fetchFollowingList() async {
    DocumentSnapshot currentUserDoc =
        await userCollections.doc(currentUser.email).get();
    List<String> fetchedFollowingList =
        List<String>.from(currentUserDoc['following'] ?? []);
    setState(() {
      followingList = fetchedFollowingList;
      followings = followingList.length;
      followers = List<String>.from(currentUserDoc['followers'] ?? []).length;
      followingStatus = {for (var email in followingList) email: true};
    });
  }

  void toggleFollow(String user) async {
    final String userToFollow = user;

    if (userToFollow != currentUser.email) {
      final DocumentReference userToFollowRef =
          userCollections.doc(userToFollow);
      final DocumentReference currentUserRef =
          userCollections.doc(currentUser.email);

      if (followingStatus[userToFollow] == true) {
        await userToFollowRef.update({
          "followers": FieldValue.arrayRemove([currentUser.email])
        });
        await currentUserRef.update({
          "following": FieldValue.arrayRemove([userToFollow])
        });

        setState(() {
          followingStatus[userToFollow] = false;
          followings--;
        });
      } else {
        await userToFollowRef.update({
          "followers": FieldValue.arrayUnion([currentUser.email])
        });
        await currentUserRef.update({
          "following": FieldValue.arrayUnion([userToFollow])
        });

        setState(() {
          followingStatus[userToFollow] = true;
          followings++;
        });
      }
    }
  }

  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(newValue),
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (newValue.isNotEmpty) {
      await userCollections.doc(currentUser.email).update({field: newValue});
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _selectedImage() async {
    try {
      final XFile? pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
        if (image != null) {
          img.Image resizedImage = img.copyResize(image, width: 400);
          final resizedFile = File(pickedFile.path)
            ..writeAsBytesSync(img.encodeJpg(resizedImage));

          final storageRef = FirebaseStorage.instance
              .ref()
              .child("user_profiles")
              .child("${currentUser.uid}.jpg");
          final uploadTask = storageRef.putFile(resizedFile);
          final snapshot = await uploadTask;
          final downloadURL = await snapshot.ref.getDownloadURL();

          await userCollections
              .doc(currentUser.email)
              .update({"image": downloadURL});

          setState(() {
            file = resizedFile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: userCollections.doc(currentUser.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: file != null
                            ? FileImage(file!)
                            : NetworkImage(userData["image"]) as ImageProvider,
                      ),
                      Positioned(
                        bottom: -10,
                        right: 10,
                        child: IconButton(
                          onPressed: _selectedImage,
                          icon: const Icon(Icons.add_a_photo),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Text(
                            followers.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Followers",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      child: Column(
                        children: [
                          Text(
                            followings.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Followings",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  "My Details",
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                BuildTextBox(
                  text: userData["username"],
                  sectionName: "username",
                  onPressed: () => editField("username"),
                ),
                const SizedBox(height: 5),
                BuildTextBox(
                  text: userData["bio"],
                  sectionName: "bio",
                  onPressed: () => editField("bio"),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Suggestions",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Users")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData) {
                        final users = snapshot.data!.docs;
                        final filteredUsers = users.where((userDoc) {
                          final user = userDoc.data() as Map<String, dynamic>;
                          final userEmail = user["email"];
                          return userEmail != currentUser.email &&
                              !followingList.contains(userEmail);
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return const Center(
                            child: Text(
                              "No suggestions available",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index].data()
                                as Map<String, dynamic>;
                            final userEmail = user["email"];

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FollowPeople(
                                onTap: () => toggleFollow(userEmail),
                                user: user["username"] ?? "unknown",
                                imageUrl: user["image"],
                                isFollowing:
                                    followingStatus[userEmail] ?? false,
                              ),
                            );
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
                const SizedBox(height: 10),
                Center(
                    child: GestureDetector(
                  onTap: signOut,
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Log Out",
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.logout,
                          color: Colors.blue,
                        )
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 30),
              ],
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
    );
  }
}
