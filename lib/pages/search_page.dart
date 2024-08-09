import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basic_social_media_app/components/text_field.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(15),
            child: BuildTextField(
              controller: _searchController,
              hint: "Search Users...",
              obscureText: false,
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text("Start typing to search..."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .where('email', isNotEqualTo: currentUserEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var results = snapshot.data!.docs;

          if (results.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              var user = results[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user["image"]),
                  radius: 20,
                ),
                title: Text(user['username']),
                subtitle: Text(user['email']),
              );
            },
          );
        } else {
          return Center();
        }
      },
    );
  }
}
