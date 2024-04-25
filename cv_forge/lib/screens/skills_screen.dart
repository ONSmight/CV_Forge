import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/personal_projects_screen.dart';

class SkillsScreen extends StatefulWidget {
  final String cvName;

  SkillsScreen({required this.cvName});

  @override
  _SkillsScreenState createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late CollectionReference skillsCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    skillsCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('skills');
  }

  void _addSkill(String skill) {
    skillsCollection.add({'skill': skill});
  }

  void _deleteSkill(String docId) {
    skillsCollection.doc(docId).delete();
  }

  void _editSkill(String docId, String newSkill) {
    skillsCollection.doc(docId).update({'skill': newSkill});
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScreenHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: skillsCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var skills = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: skills.length + 1,
                    itemBuilder: (context, index) {
                      if (index == skills.length) {
                        return _buildAddSkillButton(context);
                      }

                      var skill = skills[index];
                      var skillText = skill['skill'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    TextEditingController(text: skillText),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 10.0,
                                  ),
                                ),
                                onSubmitted: (newValue) =>
                                    _editSkill(skill.id, newValue),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, skill.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PersonalProjectsScreen(cvName: widget.cvName),
            ),
          );
        },
        label: const Text("Next"),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Icon(
        Icons.construction,
        color: Colors.green,
        size: 40.0,
      ),
      Text(
        'Skills',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
      const SizedBox(height: 16.0), // Spacing between the header and content
    ]);
  }

  // Dialog to add a new skill
  void _showAddSkillDialog(BuildContext context) {
    String newSkill = '';
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Skill'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter skill',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                newSkill = controller.text.trim();
                if (newSkill.isNotEmpty) {
                  _addSkill(newSkill);
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Dialog for confirming skill deletion
  void _showDeleteConfirmationDialog(BuildContext context, String skillId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Skill'),
          content: const Text('Are you sure you want to delete this skill?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteSkill(skillId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Button to add a new skill
  Widget _buildAddSkillButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.blue),
        ),
        onPressed: () => _showAddSkillDialog(context),
        child: const Text(
          "Add Skill",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
