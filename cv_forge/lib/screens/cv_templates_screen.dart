import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';

class CVTemplatesScreen extends StatelessWidget {
  final String cvName;

  CVTemplatesScreen({required this.cvName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: cvName,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showEditCVNameDialog(context, cvName),
          ),
        ],
      ),
      drawer: CustomDrawer(
        actionButtons: buildDrawerActionButtons(context, cvName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Text('CV Template Screen for CV: $cvName'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCVNameDialog(BuildContext context, String cvName) {
    String newCvName = cvName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit CV Name'),
          content: TextField(
            onChanged: (value) => newCvName,
            decoration: InputDecoration(hintText: 'New CV Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newCvName.isNotEmpty) {
                  var userDoc = FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid);
                  var cvDoc = userDoc.collection('cvs').doc(cvName);

                  cvDoc.get().then((docSnapshot) {
                    if (docSnapshot.exists) {
                      var data = docSnapshot.data();
                      userDoc.collection('cvs').doc(newCvName).set(data!);
                      cvDoc.delete();
                    }
                  });

                  Navigator.pop(context);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CVTemplatesScreen(cvName: newCvName),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
