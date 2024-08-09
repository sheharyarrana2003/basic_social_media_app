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
  bool isFollowing = false;

  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    fetchFollowingList();
  }

  Future<void> fetchFollowingList() async {
    DocumentSnapshot currentUserDoc =
        await userCollections.doc(currentUser.email).get();
    setState(() {
      followingList = List<String>.from(currentUserDoc['following'] ?? []);
    });
  }

  void checkFollowingStatus(String user) {
    setState(() {
      isFollowing = followingList.contains(user);
    });
  }

  void toggleFollow(String user) async {
    final String userToFollow = user;

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

  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(newValue),
            child: Text(
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
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed(
          '/login'); // Redirect to login page after sign out
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

  Future<void> _selectedImage() async {
    try {
      final XFile? pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Resize image
        final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
        if (image != null) {
          img.Image resizedImage =
              img.copyResize(image, width: 400); // Resize to 400px width
          final resizedFile = File(pickedFile.path)
            ..writeAsBytesSync(img.encodeJpg(resizedImage));

          // Upload image
          final storageRef = FirebaseStorage.instance
              .ref()
              .child("user_profiles")
              .child("${currentUser.uid}.jpg");
          final uploadTask = storageRef.putFile(resizedFile);
          uploadTask.snapshotEvents.listen((event) {
            // Optional: Show upload progress
          });
          final snapshot = await uploadTask;
          final downloadURL = await snapshot.ref.getDownloadURL();

          // Update Firestore with new image URL
          await userCollections
              .doc(currentUser.email)
              .update({"image": downloadURL}); // Ensure key matches

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
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SizedBox(height: 50),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: file != null
                            ? FileImage(file!)
                            : NetworkImage(userData["image"] ??
                                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSb51ZwKCKqU4ZrB9cfaUNclbeRiC-V-KZsfQ&s")
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: -10,
                        right: 10,
                        child: IconButton(
                          onPressed: _selectedImage,
                          icon: Icon(Icons.add_a_photo),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "My Details",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                SizedBox(height: 10),
                BuildTextBox(
                  text: userData["username"],
                  sectionName: "username",
                  onPressed: () => editField("username"),
                ),
                SizedBox(height: 10),
                BuildTextBox(
                  text: userData["bio"],
                  sectionName: "bio",
                  onPressed: () => editField("bio"),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    followingList.isEmpty ? "Suggestions" : "",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200, // Adjust height as needed
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Users")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData) {
                        final users = snapshot.data!.docs;

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user =
                                users[index].data() as Map<String, dynamic>;
                            final userEmail = user["email"];

                            // Filter out the current user and users that are already followed
                            if (userEmail != currentUser.email &&
                                !followingList.contains(userEmail)) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FollowPeople(
                                  onTap: () => toggleFollow(userEmail),
                                  user: user["username"] ?? "unknown",
                                  imageUrl: user["image"],
                                  isFollowing: isFollowing,
                                ),
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text("Error: ${snapshot.error}"),
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                    ),
                    onPressed: signOut,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Log Out",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.logout,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
