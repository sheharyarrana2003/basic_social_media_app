import 'package:basic_social_media_app/pages/log_in.dart';
import 'package:basic_social_media_app/pages/sign_up.dart';
import 'package:flutter/material.dart';

class SignUpLogIn extends StatefulWidget {
  const SignUpLogIn({super.key});

  @override
  State<SignUpLogIn> createState() => _SignUpLogInState();
}

class _SignUpLogInState extends State<SignUpLogIn> {
  bool showLogIn = true;
  void togglePage() {
    setState(() {
      showLogIn = !showLogIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogIn) {
      return LogInPage(onTap: togglePage);
    } else {
      return SignUp(onTap: togglePage);
    }
  }
}
