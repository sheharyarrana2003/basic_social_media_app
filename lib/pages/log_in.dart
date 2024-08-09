import 'package:basic_social_media_app/components/button.dart';
import 'package:basic_social_media_app/components/text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogInPage extends StatefulWidget {
  final Function()? onTap;
  const LogInPage({super.key, required this.onTap});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  late BuildContext dialogContext;

  void logIn() async {
    if (emailController.text.trim().isEmpty ||
        passController.text.trim().isEmpty) {
      showErrorMessage('Email and Password cannot be empty');
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim());

      if (context.mounted) {
        Navigator.pop(dialogContext);
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(dialogContext);
      showErrorMessage(e.message ?? 'An unknown error occurred');
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100],
        title: Text(
          'Error',
          style: TextStyle(color: Colors.red[800]),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.red[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
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
                  const Text("Welcome Back!",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const SizedBox(
                    height: 25,
                  ),
                  BuildTextField(
                      controller: emailController,
                      hint: "Email",
                      obscureText: false),
                  const SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                      controller: passController,
                      hint: "Password",
                      obscureText: true),
                  const SizedBox(
                    height: 20,
                  ),
                  BuildButton(onTap: logIn, text: "Log In"),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          "Sign Up",
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
