import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_forge/screens/profile_screen.dart';
import 'package:cv_forge/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late User currentUser;
  late CollectionReference userCollection;
  late Stream<QuerySnapshot> cvsStream;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    userCollection = FirebaseFirestore.instance.collection('users');
    cvsStream =
        userCollection.doc(currentUser.uid).collection('cvs').snapshots();
  }

  void _showCreateCVDialog(BuildContext context) {
    String cvName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter CV Name'),
          content: TextField(
            onChanged: (value) => cvName = value,
            decoration: const InputDecoration(hintText: 'CV Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (cvName.isNotEmpty) {
                  _createCV(cvName);
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCV(String cvName) async {
    await userCollection
        .doc(currentUser.uid)
        .collection('cvs')
        .doc(cvName)
        .set({
      'name': cvName,
      'created': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Forge'),
        backgroundColor: Colors.blue[900],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: cvsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching CVs'));
            }

            var cvs = snapshot.data!.docs;

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 16, // Space between columns
                mainAxisSpacing: 16, // Space between rows
                childAspectRatio: 210 / 297, // A4 aspect ratio
              ),
              itemCount: cvs.length + 1, // One extra for "Create New CV"
              itemBuilder: (context, index) {
                if (index == cvs.length) {
                  // Place "Create New CV" at the end
                  return FloatingActionButton.extended(
                    onPressed: () => _showCreateCVDialog(context),
                    backgroundColor: Colors.blue[900],
                    label: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create New CV',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10), // Space between text and icon
                        Icon(Icons.add),
                      ],
                    ),
                  );
                } else {
                  var cv = cvs[index];
                  String cvName = cv.id;

                  return GestureDetector(
                    onTap: () => _showCVActionDialog(context, cvName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[100], // Background color
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cvName,
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _showCVActionDialog(BuildContext context, String cvName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cvName),
          content: const Text('What would you like to do with this CV?'),
          actions: [
            TextButton(
              onPressed: () {
                _deleteCV(cvName);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCV(String cvName) async {
    await userCollection
        .doc(currentUser.uid)
        .collection('cvs')
        .doc(cvName)
        .delete();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: userCollection
            .doc(currentUser.uid)
            .collection('emailInfo')
            .doc('info')
            .get(),
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

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                ),
                child: Text(
                  '$username\n$email',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Sign Out'),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context); // Close the drawer
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
