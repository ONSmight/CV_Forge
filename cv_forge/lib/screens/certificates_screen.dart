import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/languages_and_interests_screen.dart'; // Change next screen import

class CertificatesScreen extends StatefulWidget {
  final String cvName;

  const CertificatesScreen({required this.cvName});

  @override
  _CertificatesScreenState createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late CollectionReference certificatesCollection;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    certificatesCollection = userDoc
        .collection('cvs')
        .doc(widget.cvName)
        .collection('certificates'); // Changed collection name
  }

  void _addCertificate(
    String certificateName,
    DateTime startDate,
    DateTime endDate,
    String description,
  ) {
    certificatesCollection.add({
      'certificate_name': certificateName,
      'start_date': DateFormat('MM/yyyy').format(startDate),
      'end_date': DateFormat('MM/yyyy').format(endDate),
      'description': description,
      'created_at': DateTime.now(), // Timestamp for ordering
    });
  }

  void _deleteCertificate(String docId) {
    certificatesCollection.doc(docId).delete();
  }

  void _editCertificate(
    String docId,
    String certificateName,
    DateTime startDate,
    DateTime endDate,
    String description,
  ) {
    certificatesCollection.doc(docId).update({
      'certificate_name': certificateName,
      'start_date': DateFormat('MM/yyyy').format(startDate),
      'end_date': DateFormat('MM/yyyy').format(endDate),
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
        stream: certificatesCollection
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var certificates = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildScreenHeader(), // Updated screen header
              ...certificates
                  .map((cert) => _buildCertificateCard(cert))
                  .toList(),
              const SizedBox(height: 16.0),
              _buildAddCertificateButton(context), // Changed button
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LanguagesAndInterestsScreen(
                  cvName: widget.cvName), // Changed next screen
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
          Icons.verified,
          color: Colors.red,
          size: 40.0,
        ),
        Text(
          'Certificates',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildAddCertificateButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.red),
        ),
        onPressed: () => _showAddCertificateDialog(context),
        child: const Text(
          "Add Certificate", // Changed text
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddCertificateDialog(BuildContext context) {
    TextEditingController certificateNameController = TextEditingController();
    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Certificate'), // Updated dialog title
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: certificateNameController,
                decoration: InputDecoration(
                  hintText: 'Certificate Name',
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
                      controller: startDateController,
                      decoration: InputDecoration(
                        hintText: 'Start Date (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            startDateController.text =
                                DateFormat('MM/yyyy').format(pickedDate);
                            startDate = pickedDate;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endDateController,
                      decoration: InputDecoration(
                        hintText: 'End Date (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            endDateController.text =
                                DateFormat('MM/yyyy').format(pickedDate);
                            endDate = pickedDate;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description',
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
                var certificateName = certificateNameController.text.trim();
                var description = descriptionController.text.trim();

                if (certificateName.isNotEmpty &&
                    startDate != null &&
                    endDate != null &&
                    description.isNotEmpty) {
                  _addCertificate(
                    certificateName,
                    startDate!,
                    endDate!,
                    description,
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

  Widget _buildCertificateCard(DocumentSnapshot certificate) {
    final data = certificate.data() as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['certificate_name'] ?? 'Unknown Certificate',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Start: ${data['start_date']}',
            ),
            Text(
              'End: ${data['end_date']}',
            ),
            Text(
              data['description'] ?? 'No description provided.',
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditCertificateDialog(context, certificate),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmationDialog(context, certificate.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCertificateDialog(
      BuildContext context, DocumentSnapshot certificate) {
    final data = certificate.data() as Map<String, dynamic>;

    TextEditingController certificateNameController =
        TextEditingController(text: data['certificate_name']);
    TextEditingController startDateController = TextEditingController(
      text: data['start_date'],
    );
    TextEditingController endDateController = TextEditingController(
      text: data['end_date'],
    );
    TextEditingController descriptionController =
        TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Certificate'), // Updated dialog title
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: certificateNameController,
                decoration: InputDecoration(
                  hintText: 'Certificate Name',
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
                      controller: startDateController,
                      decoration: InputDecoration(
                        hintText: 'Start Date (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            startDateController.text =
                                DateFormat('MM/yyyy').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endDateController,
                      decoration: InputDecoration(
                        hintText: 'End Date (MM/YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () => _pickDate(
                        context,
                        (pickedDate) {
                          if (pickedDate != null) {
                            endDateController.text =
                                DateFormat('MM/yyyy').format(pickedDate);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description',
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
                var certificateName = certificateNameController.text.trim();
                var description = descriptionController.text.trim();

                if (certificateName.isNotEmpty &&
                    startDateController.text.isNotEmpty &&
                    endDateController.text.isNotEmpty &&
                    description.isNotEmpty) {
                  _editCertificate(
                    certificate.id,
                    certificateName,
                    DateFormat('MM/yyyy').parse(startDateController.text),
                    DateFormat('MM/yyyy').parse(endDateController.text),
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

  void _showDeleteConfirmationDialog(
      BuildContext context, String certificateId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Certificate'),
          content:
              const Text('Are you sure you want to delete this certificate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCertificate(certificateId);
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
