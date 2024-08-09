import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final void Function()? onTap;
  final bool
      isFollowing; // Indicates if the current user is following the post's user

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(
          isFollowing
              ? "Unfollow"
              : "Follow", // Toggle between "Follow" and "Unfollow"
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
      ),
    );
  }
}
