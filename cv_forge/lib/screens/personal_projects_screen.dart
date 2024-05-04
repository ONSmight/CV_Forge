import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/work_experience_screen.dart';

class PersonalProjectsScreen extends StatefulWidget {
  final String cvName;

  const PersonalProjectsScreen({required this.cvName});

  @override
  _PersonalProjectsScreenState createState() => _PersonalProjectsScreenState();
}

class _PersonalProjectsScreenState extends State<PersonalProjectsScreen> {
  late CollectionReference personalProjectsCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    personalProjectsCollection = userDoc
        .collection('cvs')
        .doc(widget.cvName)
        .collection('personal_projects');
  }

  void _addPersonalProject(
    String projectName,
    DateTime fromDate,
    DateTime? toDate,
    bool isPresent,
    String description,
  ) {
    personalProjectsCollection.add({
      'projectName': projectName,
      'fromDate': DateFormat('MM/yyyy').format(fromDate),
      'toDate': isPresent ? 'present' : DateFormat('MM/yyyy').format(toDate!),
      'description': description,
      'created_at': DateTime.now(), // Adding a creation timestamp
    });
  }

  void _deletePersonalProject(String docId) {
    personalProjectsCollection.doc(docId).delete();
  }

  void _editPersonalProject(
    String docId,
    String projectName,
    DateTime fromDate,
    DateTime? toDate,
    bool isPresent,
    String description,
  ) {
    personalProjectsCollection.doc(docId).update({
      'projectName': projectName,
      'fromDate': DateFormat('MM/yyyy').format(fromDate),
      'toDate': isPresent ? 'present' : DateFormat('MM/yyyy').format(toDate!),
      'description': description,
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
        stream: personalProjectsCollection
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var projects = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildScreenHeader(),
              ...projects.map((project) => _buildProjectCard(project)).toList(),
              const SizedBox(height: 16.0), // Spacing before the button
              _buildAddPersonalProjectButton(context),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkExperienceScreen(cvName: widget.cvName),
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
          Icons.book,
          color: Colors.brown,
          size: 40.0,
        ),
        Text(
          'Personal Projects',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.brown[700],
          ),
        ),
        const SizedBox(height: 16.0), // Spacing between the header and content
      ],
    );
  }

  Widget _buildAddPersonalProjectButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.brown),
        ),
        onPressed: () => _showAddPersonalProjectDialog(context),
        child: const Text(
          "Add Personal Project",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddPersonalProjectDialog(BuildContext context) {
    String projectName = '';
    DateTime? fromDate;
    DateTime? toDate;
    bool isPresent = false;
    String description = '';

    TextEditingController projectNameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController fromDateController = TextEditingController();
    TextEditingController toDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Personal Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: projectNameController,
                decoration: InputDecoration(
                  hintText: 'Project Name',
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
                            fromDate = pickedDate;
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
                            toDate = pickedDate;
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
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Project Description',
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
                projectName = projectNameController.text.trim();
                description = descriptionController.text.trim();

                if (projectName.isNotEmpty &&
                    fromDate != null &&
                    (toDate != null || isPresent) &&
                    description.isNotEmpty) {
                  _addPersonalProject(
                    projectName,
                    fromDate!,
                    toDate,
                    isPresent,
                    description,
                  );
                  Navigator.pop(context);
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
      helpText: 'Select a date',
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  Widget _buildProjectCard(DocumentSnapshot project) {
    final data = project.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['projectName'] ?? 'Unknown Project',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'From: ${data['fromDate']}',
            ),
            Text(
              'To: ${data['toDate']}',
            ),
            Text(
              data['description'] ?? 'No description provided.',
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditPersonalProjectDialog(context, project),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmationDialog(context, project.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPersonalProjectDialog(
    BuildContext context,
    DocumentSnapshot project,
  ) {
    final data = project.data() as Map<String, dynamic>;

    TextEditingController projectNameController =
        TextEditingController(text: data['projectName']);
    TextEditingController descriptionController =
        TextEditingController(text: data['description']);
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
          title: const Text('Edit Personal Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: projectNameController,
                decoration: InputDecoration(
                  hintText: 'Project Name',
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
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Project Description',
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
                var projectName = projectNameController.text.trim();
                var description = descriptionController.text.trim();

                if (projectName.isNotEmpty &&
                    fromDateController.text.isNotEmpty &&
                    (toDateController.text.isNotEmpty || isPresent) &&
                    description.isNotEmpty) {
                  _editPersonalProject(
                    project.id,
                    projectName,
                    DateFormat('MM/yyyy').parse(fromDateController.text),
                    isPresent
                        ? null
                        : DateFormat('MM/yyyy').parse(toDateController.text),
                    isPresent,
                    description,
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

  void _showDeleteConfirmationDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePersonalProject(projectId);
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
