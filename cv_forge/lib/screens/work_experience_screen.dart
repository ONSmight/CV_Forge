import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/certificates_screen.dart';

class WorkExperienceScreen extends StatefulWidget {
  final String cvName;

  const WorkExperienceScreen({required this.cvName});

  @override
  _WorkExperienceScreenState createState() => _WorkExperienceScreenState();
}

class _WorkExperienceScreenState extends State<WorkExperienceScreen> {
  late CollectionReference workExperienceCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    workExperienceCollection = userDoc
        .collection('cvs')
        .doc(widget.cvName)
        .collection('work_experience');
  }

  void _addWorkExperience(
    String position,
    String workplace,
    DateTime fromDate,
    DateTime? toDate,
    bool isPresent,
    String achievements,
  ) {
    workExperienceCollection.add({
      'position': position,
      'workplace': workplace,
      'fromDate': DateFormat('MM/yyyy').format(fromDate),
      'toDate': isPresent ? 'present' : DateFormat('MM/yyyy').format(toDate!),
      'achievements': achievements,
      'created_at': DateTime.now(), // Timestamp for ordering
    });
  }

  void _deleteWorkExperience(String docId) {
    workExperienceCollection.doc(docId).delete();
  }

  void _editWorkExperience(
    String docId,
    String position,
    String workplace,
    DateTime fromDate,
    DateTime? toDate,
    bool isPresent,
    String achievements,
  ) {
    workExperienceCollection.doc(docId).update({
      'position': position,
      'workplace': workplace,
      'fromDate': DateFormat('MM/yyyy').format(fromDate),
      'toDate': isPresent ? 'present' : DateFormat('MM/yyyy').format(toDate!),
      'achievements': achievements,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: workExperienceCollection
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var experiences = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildScreenHeader(),
              ...experiences
                  .map((exp) => _buildWorkExperienceCard(exp))
                  .toList(),
              const SizedBox(height: 16.0),
              _buildAddWorkExperienceButton(context),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificatesScreen(cvName: widget.cvName),
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
        const Icon(
          Icons.business_center,
          color: Colors.indigo,
          size: 40.0,
        ),
        Text(
          'Work Experience',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[700],
          ),
        ),
        const SizedBox(height: 16.0), // Spacing between the header and content
      ],
    );
  }

  Widget _buildAddWorkExperienceButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.indigo.shade700),
        ),
        onPressed: () => _showAddWorkExperienceDialog(context),
        child: const Text(
          "Add Work Experience",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddWorkExperienceDialog(BuildContext context) {
    TextEditingController positionController = TextEditingController();
    TextEditingController workplaceController = TextEditingController();
    TextEditingController fromDateController = TextEditingController();
    TextEditingController toDateController = TextEditingController();
    TextEditingController achievementsController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;
    bool isPresent = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Work Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  hintText: 'Position/Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: workplaceController,
                decoration: InputDecoration(
                  hintText: 'Workplace',
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
                                DateFormat('MM/yyyy').format(pickedDate);
                            fromDate = pickedDate;
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
                            toDate = pickedDate;
                          }
                        },
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isPresent,
                    onChanged: (value) {
                      isPresent = value!;
                      if (isPresent) {
                        toDateController.clear();
                      }
                    },
                  ),
                  const Text("Present"),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: achievementsController,
                decoration: InputDecoration(
                  hintText: 'Achievements/Tasks',
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
                var position = positionController.text.trim();
                var workplace = workplaceController.text.trim();
                var achievements = achievementsController.text.trim();

                if (position.isNotEmpty &&
                    workplace.isNotEmpty &&
                    fromDate != null &&
                    (toDate != null || isPresent) &&
                    achievements.isNotEmpty) {
                  _addWorkExperience(
                    position,
                    workplace,
                    fromDate!,
                    toDate,
                    isPresent,
                    achievements,
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
    DateTime initialDate = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      fieldLabelText: 'Select a date',
      fieldHintText: 'MM/YYYY',
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  Widget _buildWorkExperienceCard(DocumentSnapshot experience) {
    final data = experience.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['position'] ?? 'Unknown Position',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Workplace: ${data['workplace']}',
            ),
            Text(
              'From: ${data['fromDate']}',
            ),
            Text(
              'To: ${data['toDate']}',
            ),
            Text(
              data['achievements'] ?? 'No achievements provided.',
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditWorkExperienceDialog(context, experience),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmationDialog(context, experience.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWorkExperienceDialog(
      BuildContext context, DocumentSnapshot experience) {
    final data = experience.data() as Map<String, dynamic>;

    TextEditingController positionController =
        TextEditingController(text: data['position']);
    TextEditingController workplaceController =
        TextEditingController(text: data['workplace']);
    TextEditingController fromDateController = TextEditingController(
      text: data['fromDate'],
    );
    TextEditingController toDateController = TextEditingController(
      text: data['toDate'] == 'present' ? '' : data['toDate'],
    );
    bool isPresent = data['toDate'] == 'present';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Work Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  hintText: 'Position/Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: workplaceController,
                decoration: InputDecoration(
                  hintText: 'Workplace',
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
                                DateFormat('MM/yyyy').format(pickedDate);
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
                        toDateController.clear();
                      });
                    },
                  ),
                  const Text("Present"),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: data['achievements']),
                decoration: InputDecoration(
                  hintText: 'Achievements/Tasks',
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
                var position = positionController.text.trim();
                var workplace = workplaceController.text.trim();
                var achievements = data['achievements'];

                if (position.isNotEmpty &&
                    workplace.isNotEmpty &&
                    fromDateController.text.isNotEmpty &&
                    (toDateController.text.isNotEmpty || isPresent) &&
                    achievements.isNotEmpty) {
                  _editWorkExperience(
                    experience.id,
                    position,
                    workplace,
                    DateFormat('MM/yyyy').parse(fromDateController.text),
                    isPresent
                        ? null
                        : DateFormat('MM/yyyy').parse(toDateController.text),
                    isPresent,
                    achievements,
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

  void _showDeleteConfirmationDialog(
      BuildContext context, String experienceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Experience'),
          content: const Text(
              'Are you sure you want to delete this work experience?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteWorkExperience(experienceId);
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
