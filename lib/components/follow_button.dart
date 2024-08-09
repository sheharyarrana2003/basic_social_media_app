import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final void Function()? onTap;
  final bool isFollowing;

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
          isFollowing ? "Unfollow" : "Follow",
          style: const TextStyle(color: Colors.blue, fontSize: 10),
        ),
      ),
    );
  }
}
