import 'dart:io';
import 'package:basic_social_media_app/components/button.dart';
import 'package:basic_social_media_app/components/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final userPostsCollection =
      FirebaseFirestore.instance.collection("User Posts");
  final userCollections = FirebaseFirestore.instance.collection("Users");
  final currentUser = FirebaseAuth.instance.currentUser!;
  File? file;
  final ImagePicker imagePicker = ImagePicker();
  final TextEditingController captionController = TextEditingController();

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

          setState(() {
            file = resizedFile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select image: $e")),
      );
    }
  }

  Future<void> _uploadPost() async {
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("user_posts")
          .child(
              "${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final uploadTask = storageRef.putFile(file!);
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      DocumentSnapshot userDoc =
          await userCollections.doc(currentUser.email).get();
      String username = userDoc.get("username");
      String imageUri = userDoc.get("image");
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': captionController.text.trim(),
        'TimeStamp': Timestamp.now(),
        'Likes': [],
        'username': username,
        'image': imageUri,
        'postImage': downloadURL,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post uploaded successfully!")),
      );

      setState(() {
        file = null;
        captionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload post: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _selectedImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: file != null
                      ? Image.file(file!, fit: BoxFit.cover)
                      : const Center(
                          child: Text(
                          "Tap to select an image",
                          style: TextStyle(color: Colors.black),
                        )),
                ),
              ),
              const SizedBox(height: 16),
              BuildTextField(
                  controller: captionController,
                  hint: "Add a Caption",
                  obscureText: false),
              const SizedBox(height: 16),
              BuildButton(onTap: _uploadPost, text: "Submit Post")
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }
}
