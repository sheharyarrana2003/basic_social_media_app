import 'package:basic_social_media_app/components/button.dart';
import 'package:basic_social_media_app/components/text_field.dart';
import 'package:basic_social_media_app/pages/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  final Function()? onTap;
  const SignUp({super.key, required this.onTap});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final userNameControler = TextEditingController();
  final emailControler = TextEditingController();
  final passControler = TextEditingController();
  final confirmPassControler = TextEditingController();

  void signUp() async {
    if (emailControler.text.trim().isEmpty &&
        passControler.text.trim().isEmpty) {
      Navigator.pop(context);
      showMessage("Email and Password cannot be empty");
      return;
    }

    if (passControler.text.trim() != confirmPassControler.text.trim()) {
      Navigator.pop(context);
      showMessage("Passwords don't match");
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailControler.text.trim(),
              password: passControler.text.trim());
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
        "username": userNameControler.text.trim(),
        "bio": "Empty Bio..",
        "followers": [],
        "email": emailControler.text.trim(),
        "image": "",
        "following": []
      });

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showMessage(e.message ?? "An error occurred");
    }
  }

  void showMessage(String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text(
                "Error",
                style: TextStyle(color: Colors.red),
              ),
              content: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.grey[100],
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 100,
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Text("Create Account",
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(
                    height: 25,
                  ),
                  BuildTextField(
                      controller: userNameControler,
                      hint: "User Name",
                      obscureText: false),
                  const SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: emailControler,
                      hint: "Email",
                      obscureText: false),
                  const SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: passControler,
                      hint: "Password",
                      obscureText: true),
                  const SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: confirmPassControler,
                      hint: "Confirm Password",
                      obscureText: true),
                  const SizedBox(
                    height: 20,
                  ),
                  BuildButton(onTap: signUp, text: "Sign Up"),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have account?",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
