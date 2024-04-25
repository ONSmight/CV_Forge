import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_forge/screens/profile_screen.dart';
import 'package:cv_forge/auth/login_screen.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "CV Forge",
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: CustomDrawer(
        actionButtons: [
          _buildCustomTile(
            context,
            icon: Icons.exit_to_app,
            text: 'Sign Out',
            backgroundColor: Colors.red.shade700,
            onTap: _signOut,
          ),
        ],
      ),
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
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 210 / 297, // A4 paper aspect ratio
              ),
              itemCount: cvs.length + 1,
              itemBuilder: (context, index) {
                if (index == cvs.length) {
                  return FloatingActionButton.extended(
                    onPressed: () => _showCreateCVDialog(context),
                    backgroundColor: Colors.blue[800],
                    label: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create New CV',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Icon(Icons.add),
                      ],
                    ),
                  );
                } else {
                  var cv = cvs[index];
                  String cvName = cv.id;

                  return GestureDetector(
                    onLongPress: () => _showCVActionDialog(context, cvName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(cvName: cvName),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade100,
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

  void _signOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showCreateCVDialog(BuildContext context) {
    String cvName = ''; // Ensure this variable is mutable and updated correctly
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter CV Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'CV Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cvName = controller.text
                    .trim(); // Update cvName with text from the field
                if (cvName.isNotEmpty) {
                  _createCV(cvName);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(cvName: cvName),
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

  void _showCVActionDialog(BuildContext context, String cvName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$cvName'),
          content: Text('What would you like to do with this CV?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCV(cvName);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(cvName: cvName),
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

  Future<void> _deleteCV(String cvName) {
    return userCollection
        .doc(currentUser.uid)
        .collection('cvs')
        .doc(cvName)
        .delete();
  }
}

Widget _buildCustomTile(
  BuildContext context, {
  required IconData icon,
  required String text,
  required Color? backgroundColor,
  required Function() onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}
