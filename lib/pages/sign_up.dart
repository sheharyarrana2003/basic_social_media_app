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
    showDialog(
      context: context,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

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
        Navigator.pop(context); // Dismiss the progress indicator

        // Navigate to the ProfilePage and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
          (route) => false, // Removes all routes
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showMessage(e.message ?? "An error occurred");
    }
  }

  void showMessage(String message) async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(message),
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
                  Icon(
                    Icons.lock,
                    size: 100,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Text("Create Account",
                      style: TextStyle(color: Colors.grey[700])),
                  SizedBox(
                    height: 25,
                  ),
                  BuildTextField(
                      controller: userNameControler,
                      hint: "User Name",
                      obscureText: false),
                  SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: emailControler,
                      hint: "Email",
                      obscureText: false),
                  SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: passControler,
                      hint: "Password",
                      obscureText: true),
                  SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: confirmPassControler,
                      hint: "Confirm Password",
                      obscureText: true),
                  SizedBox(
                    height: 20,
                  ),
                  BuildButton(onTap: signUp, text: "Sign Up"),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have account?",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
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
