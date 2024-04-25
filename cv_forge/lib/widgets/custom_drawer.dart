import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatelessWidget {
  final List<Widget> actionButtons;

  const CustomDrawer({
    Key? key,
    required this.actionButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userCollection = FirebaseFirestore.instance.collection('users');
    final userDoc = userCollection
        .doc(currentUser.uid)
        .collection('emailInfo')
        .doc('info')
        .get();

    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: userDoc,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching user info'));
          }

          var userData = snapshot.data!;
          String username = userData['username'] ?? 'Unknown';
          String email = userData['email'] ?? 'Unknown';

          return Container(
            color: Colors.blue[200], // Background color for the entire drawer
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Ensure full width
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue[800], // Ensures full-width coverage
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft, // Keep text at bottom-left
                    child: Text(
                      '$username\n$email',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(0), // No extra padding
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.all(8.0), // Padding for buttons
                        child: Column(
                          children: actionButtons, // Include the custom buttons
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
