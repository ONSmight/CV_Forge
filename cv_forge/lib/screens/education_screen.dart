import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/skills_screen.dart';

class EducationScreen extends StatefulWidget {
  final String cvName;

  const EducationScreen({required this.cvName});

  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late CollectionReference educationCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    educationCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('education');
  }

  void _addEducation(
    String studyProgram,
    String placeOfEducation,
    String fromDate,
    String toDate,
    String gpaOrAchievements,
  ) {
    educationCollection.add({
      'studyProgram': studyProgram,
      'placeOfEducation': placeOfEducation,
      'fromDate': fromDate,
      'toDate': toDate,
      'gpaOrAchievements': gpaOrAchievements,
      'created_at': DateTime.now(), // For ordering
    });
  }

  void _editEducation(
    String docId,
    String studyProgram,
    String placeOfEducation,
    String fromDate,
    String toDate,
    String gpaOrAchievements,
  ) {
    educationCollection.doc(docId).update({
      'studyProgram': studyProgram,
      'placeOfEducation': placeOfEducation,
      'fromDate': fromDate,
      'toDate': toDate,
      'gpaOrAchievements': gpaOrAchievements,
    });
  }

  void _deleteEducation(String docId) {
    educationCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.cvName,
        backgroundColor: Colors.blue.shade700, // New color
      ),
      drawer: CustomDrawer(
        actionButtons: buildDrawerActionButtons(context, widget.cvName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: educationCollection
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var education = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildScreenHeader(),
              ...education.map((ed) => _buildEducationCard(ed)).toList(),
              const SizedBox(height: 16.0),
              _buildAddEducationButton(context),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SkillsScreen(
                  cvName: widget.cvName), // Navigates to SkillsScreen
            ),
          );
        },
        label: const Text("Next"),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.school,
          color: Colors.purple[700], // Icon for education
          size: 40.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Education',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700], // Color for header
          ),
        ),
        const SizedBox(height: 16.0), // Spacing between the header and content
      ],
    );
  }

  Widget _buildAddEducationButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.purple[700]),
        ),
        onPressed: () => _showAddEducationDialog(context),
        child: const Text(
          "Add Education",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddEducationDialog(BuildContext context) {
    TextEditingController studyProgramController = TextEditingController();
    TextEditingController placeOfEducationController = TextEditingController();
    TextEditingController fromDateController = TextEditingController();
    TextEditingController toDateController = TextEditingController();
    TextEditingController gpaOrAchievementsController = TextEditingController();
    bool isPresent = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Education'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studyProgramController,
                decoration: InputDecoration(
                  hintText: 'Study Program',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: placeOfEducationController,
                decoration: InputDecoration(
                  hintText: 'Place of Education',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromDateController,
                      decoration: InputDecoration(
                        hintText: 'From (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            fromDateController.text =
                                DateFormat('MM/YYYY').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: toDateController,
                      decoration: InputDecoration(
                        hintText: 'To (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      enabled: !isPresent,
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            toDateController.text =
                                DateFormat('MM/YYYY').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isPresent,
                    onChanged: (value) {
                      setState(() {
                        isPresent = value!;
                        if (isPresent) {
                          toDateController.clear();
                        }
                      });
                    },
                  ),
                  const Text("Present"),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gpaOrAchievementsController,
                decoration: InputDecoration(
                  hintText: 'GPA/Achievements',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var studyProgram = studyProgramController.text.trim();
                var placeOfEducation = placeOfEducationController.text.trim();
                var gpaOrAchievements = gpaOrAchievementsController.text.trim();

                if (studyProgram.isNotEmpty &&
                    placeOfEducation.isNotEmpty &&
                    fromDateController.text.isNotEmpty &&
                    (isPresent || toDateController.text.isNotEmpty)) {
                  var fromDate = fromDateController.text;
                  var toDate = isPresent ? 'present' : toDateController.text;

                  _addEducation(
                    studyProgram,
                    placeOfEducation,
                    fromDate,
                    toDate,
                    gpaOrAchievements,
                  );
                  Navigator.pop(context); // Close dialog on successful add
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      fieldLabelText: 'Select a date',
      fieldHintText: 'MM/YYYY',
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  Widget _buildEducationCard(DocumentSnapshot education) {
    final data = education.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['studyProgram'] ?? 'Unknown Program',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Place of Education: ${data['placeOfEducation'] ?? "Unknown"}',
            ),
            Text(
              'From: ${data['fromDate']}',
            ),
            Text(
              'To: ${data['toDate']}',
            ),
            Text(
              'GPA/Achievements: ${data['gpaOrAchievements'] ?? "Not provided."}',
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditEducationDialog(context, education),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(
                    context,
                    education.id,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEducationDialog(
      BuildContext context, DocumentSnapshot education) {
    final data = education.data() as Map<String, dynamic>;

    TextEditingController studyProgramController =
        TextEditingController(text: data['studyProgram']);
    TextEditingController placeOfEducationController =
        TextEditingController(text: data['placeOfEducation']);
    TextEditingController fromDateController =
        TextEditingController(text: data['fromDate']);
    TextEditingController toDateController = TextEditingController(
        text: data['toDate'] == 'present' ? '' : data['toDate']);
    TextEditingController gpaOrAchievementsController =
        TextEditingController(text: data['gpaOrAchievements']);
    bool isPresent = data['toDate'] == 'present';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Education'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studyProgramController,
                decoration: InputDecoration(
                  hintText: 'Study Program',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: placeOfEducationController,
                decoration: InputDecoration(
                  hintText: 'Place of Education',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromDateController,
                      decoration: InputDecoration(
                        hintText: 'From (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            fromDateController.text =
                                DateFormat('MM/YYYY').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: toDateController,
                      decoration: InputDecoration(
                        hintText: 'To (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      enabled: !isPresent,
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            toDateController.text =
                                DateFormat('MM/yyyy').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isPresent,
                    onChanged: (value) {
                      setState(() {
                        isPresent = value!;
                        if (isPresent) {
                          toDateController.clear();
                        }
                      });
                    },
                  ),
                  const Text("Present"),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gpaOrAchievementsController,
                decoration: InputDecoration(
                  hintText: 'GPA/Achievements',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0)),
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
                var studyProgram = studyProgramController.text.trim();
                var placeOfEducation = placeOfEducationController.text.trim();
                var gpaOrAchievements = gpaOrAchievementsController.text.trim();

                if (studyProgram.isNotEmpty &&
                    placeOfEducation.isNotEmpty &&
                    fromDateController.text.isNotEmpty &&
                    (isPresent || toDateController.text.isNotEmpty)) {
                  _editEducation(
                    education.id,
                    studyProgram,
                    placeOfEducation,
                    fromDateController.text,
                    isPresent ? 'present' : toDateController.text,
                    gpaOrAchievements,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String educationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Education'),
          content: const Text(
              'Are you sure you want to delete this education record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteEducation(educationId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
