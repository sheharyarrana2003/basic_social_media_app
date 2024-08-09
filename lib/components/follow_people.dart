import 'dart:io';
import 'package:flutter/material.dart';

class FollowPeople extends StatelessWidget {
  final String user;
  final VoidCallback onTap;
  final File? file;
  final String? imageUrl;
  final bool isFollowing;

  const FollowPeople({
    required this.user,
    required this.onTap,
    this.file,
    this.imageUrl,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: file != null
                  ? FileImage(file!)
                  : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? NetworkImage(imageUrl!) as ImageProvider
                      : const NetworkImage(
                          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSb51ZwKCKqU4ZrB9cfaUNclbeRiC-V-KZsfQ&s"),
            ),
            const SizedBox(height: 8),
            Text(
              user,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 30,
              child: OutlinedButton(
                onPressed: onTap,
                child: Text(
                  isFollowing ? "Unfollow" : "Follow",
                  style: const TextStyle(color: Colors.blue, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
