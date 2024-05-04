import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/cv_templates_screen.dart';

class LanguagesAndInterestsScreen extends StatefulWidget {
  final String cvName;

  const LanguagesAndInterestsScreen({super.key, required this.cvName});

  @override
  _LanguagesAndInterestsScreenState createState() =>
      _LanguagesAndInterestsScreenState();
}

class _LanguagesAndInterestsScreenState
    extends State<LanguagesAndInterestsScreen> {
  late CollectionReference languagesCollection;
  late CollectionReference interestsCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    languagesCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('languages');
    interestsCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('interests');
  }

  void _addLanguage(String language, String level) {
    languagesCollection.add({
      'language': language,
      'level': level,
    });
  }

  void _addInterest(String interest) {
    interestsCollection.add({
      'interest': interest,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.cvName,
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: CustomDrawer(
        actionButtons: buildDrawerActionButtons(context, widget.cvName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildScreenHeader(),
          _buildLanguagesSection(),
          _buildInterestsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CVTemplatesScreen(cvName: widget.cvName),
            ),
          );
        },
        label: const Text('Next'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.language, // Changed icon
          color: Colors.cyan, // Changed color
          size: 40.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Languages & Interests', // Changed text
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.cyan[700], // Consistent color
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Languages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        StreamBuilder<QuerySnapshot>(
          stream: languagesCollection.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            var languages = snapshot.data!.docs;

            return Column(
              children: [
                ...languages.map((lang) => _buildLanguageCard(lang)).toList(),
                const SizedBox(height: 16.0),
                _buildAddLanguageButton(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        StreamBuilder<QuerySnapshot>(
          stream: interestsCollection.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            var interests = snapshot.data!.docs;

            return Column(
              children: [
                ...interests
                    .map((interest) => _buildInterestCard(interest))
                    .toList(),
                const SizedBox(height: 16.0),
                _buildAddInterestButton(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddLanguageButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.cyan[700]),
        ),
        onPressed: () => _showAddLanguageDialog(context),
        child: const Text(
          "Add Language",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddLanguageDialog(BuildContext context) {
    TextEditingController languageController = TextEditingController();
    String? selectedLevel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: languageController,
                decoration: InputDecoration(
                  hintText: 'Language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                hint: const Text('Select Level'),
                items: const [
                  DropdownMenuItem(
                    value: "Basic",
                    child: Text("Basic"),
                  ),
                  DropdownMenuItem(
                    value: "Conversational",
                    child: Text("Conversational"),
                  ),
                  DropdownMenuItem(
                    value: "Proficient",
                    child: Text("Proficient"),
                  ),
                  DropdownMenuItem(
                    value: "Fluent",
                    child: Text("Fluent"),
                  ),
                ],
                onChanged: (value) {
                  selectedLevel = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var language = languageController.text.trim();
                if (language.isNotEmpty && selectedLevel != null) {
                  _addLanguage(language, selectedLevel!);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill the fields.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddInterestButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.cyan[700]),
        ),
        onPressed: () => _showAddInterestDialog(context),
        child: const Text(
          "Add Interest",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddInterestDialog(BuildContext context) {
    TextEditingController interestController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Interest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: interestController,
                decoration: InputDecoration(
                  hintText: 'Interest',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var interest = interestController.text.trim();
                if (interest.isNotEmpty) {
                  _addInterest(interest);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill the fields.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageCard(DocumentSnapshot languageDoc) {
    final data = languageDoc.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language: ${data['language']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Level: ${data['level']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestCard(DocumentSnapshot interestDoc) {
    final data = interestDoc.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          data['interest'],
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
