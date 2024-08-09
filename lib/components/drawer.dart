import 'package:basic_social_media_app/components/list_tile.dart';
import 'package:flutter/material.dart';

class BuildDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onLogOutTap;
  const BuildDrawer(
      {super.key, required this.onProfileTap, required this.onLogOutTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 70,
                ),
              ),
              BuildListTile(
                icon: Icons.home,
                text: "H O M E",
                onTap: () => Navigator.pop(context),
              ),
              BuildListTile(
                icon: Icons.person,
                text: "P R O F I L E",
                onTap: onProfileTap,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 25.0),
            child: BuildListTile(
              icon: Icons.logout,
              text: "L O G O U T",
              onTap: onLogOutTap,
            ),
          ),
        ],
      ),
    );
  }
}
