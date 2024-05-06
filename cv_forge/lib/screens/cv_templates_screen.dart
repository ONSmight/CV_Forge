import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class CVTemplatesScreen extends StatelessWidget {
  final String cvName;

  CVTemplatesScreen({super.key, required this.cvName});
  late pw.TextStyle sectionHeaderFontStyle;
  late pw.TextStyle sectionTextFontStyle;

  Future<File> generateCvTemplate1(String cvName) async {
    final pdf = pw.Document();
    sectionHeaderFontStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold, fontSize: 20, color: PdfColors.blue900);
    sectionTextFontStyle = const pw.TextStyle(fontSize: 16);

    // Fetch data from Firebase
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    var profileCollection =
        userDoc.collection('cvs').doc(cvName).collection('profile');
    var contactCollection =
        userDoc.collection('cvs').doc(cvName).collection('contact');
    var linksCollection =
        userDoc.collection('cvs').doc(cvName).collection('links');
    var skillsCollection =
        userDoc.collection('cvs').doc(cvName).collection('skills');
    var workExperienceCollection =
        userDoc.collection('cvs').doc(cvName).collection('work_experience');
    var educationCollection =
        userDoc.collection('cvs').doc(cvName).collection('education');
    var personalProjectsCollection =
        userDoc.collection('cvs').doc(cvName).collection('personal_projects');
    var languagesCollection =
        userDoc.collection('cvs').doc(cvName).collection('languages');
    var interestsCollection =
        userDoc.collection('cvs').doc(cvName).collection('interests');
    var certificatesCollection =
        userDoc.collection('cvs').doc(cvName).collection('certificates');

    // Load the profile image data beforehand
    pw.MemoryImage? profileImage;
    if (profileCollection != null) {
      final imageData = await FirebaseStorage.instance
          .ref('profile_images/$cvName')
          .getData();
      if (imageData != null) {
        profileImage = pw.MemoryImage(imageData);
      }
    }

    // Retrieve profile data and other collections
    var profileDoc = await profileCollection.doc('main').get();
    var contactInfoDoc = await contactCollection.doc('info').get();
    var links = await linksCollection.get();
    var education = await educationCollection.get();
    var skills = await skillsCollection.get();
    var workExperience = await workExperienceCollection.get();
    var personalProjects = await personalProjectsCollection.get();
    var languages = await languagesCollection.get();
    var interests = await interestsCollection.get();
    var certificates = await certificatesCollection.get();

    // Build the PDF page(s)
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          List<pw.Widget> content = [];

          // First row with profile pic, name, and profession
          content.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null)
                    pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 10),
                        child: pw.Image(profileImage, height: 100, width: 100)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileDoc.exists)
                    pw.Text(
                      profileDoc.data()?['name'] ?? '',
                      style: const pw.TextStyle(fontSize: 24),
                    ),
                  if (profileDoc.exists)
                    pw.Text(
                      profileDoc.data()?['profession'] ?? '',
                      style: const pw.TextStyle(fontSize: 18),
                    ),
                ],
              ),
            ],
          ));

          // Solid line
          content.add(pw.Divider(endIndent: 5));

          // Second row with phone, address, and links
          content.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (contactInfoDoc.exists &&
                        contactInfoDoc.data()?['phone'] != null)
                      pw.Text("${contactInfoDoc.data()?['phone']}"),
                    if (contactInfoDoc.exists &&
                        contactInfoDoc.data()?['address'] != null)
                      pw.Text("${contactInfoDoc.data()?['address']}"),
                  ]),
              if (links.docs.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: links.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return pw.Text(
                      "${data['social_media_link']}",
                      style: const pw.TextStyle(
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline),
                    );
                  }).toList(),
                ),
            ],
          ));

          // Solid line
          content.add(pw.Divider());

          // Third row with multiple columns
          content.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // First column: Education, Personal Projects, Languages, Interests
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildEducationSection(education.docs),
                      pw.Divider(endIndent: 20),
                      _buildPersonalProjectsSection(personalProjects.docs),
                      pw.Divider(endIndent: 20),
                      _buildLanguagesSection(languages.docs),
                      pw.Divider(endIndent: 20),
                      _buildInterestsSection(interests.docs),
                    ],
                  ),
                ),
                // Second column: Skills, Work Experience, Certificates
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSkillsSection(skills.docs),
                      pw.Divider(endIndent: 20),
                      _buildWorkExperienceSection(workExperience.docs),
                      pw.Divider(endIndent: 20),
                      _buildCertificatesSection(certificates.docs),
                    ],
                  ),
                ),
              ],
            ),
          );

          return content;
        },
      ),
    );

    // Ask for a directory to save the PDF
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose a directory to save your CV",
    );

    if (result == null) {
      // If the user cancels the file picker, return early
      throw Exception("No directory selected");
    }

    // Save the PDF in the chosen directory
    final file = File("$result/$cvName.pdf");
    await file.writeAsBytes(await pdf.save());

    return file; // Return the generated file
  }

  pw.Widget _buildEducationSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Education", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Column(children: [
            pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10.0),
                child: pw.Text(
                    "${data['studyProgram']} at ${data['placeOfEducation']} (${data['fromDate']} - ${data['toDate']})",
                    style: sectionTextFontStyle))
          ]);
        }).toList(),
      ],
    );
  }

  pw.Widget _buildPersonalProjectsSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Personal Projects", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10.0),
              child: pw.Text(
                  "${data['projectName']} (${data['fromDate']} - ${data['toDate']}) - ${data['description']}",
                  style: sectionTextFontStyle));
        }).toList(),
      ],
    );
  }

  pw.Widget _buildLanguagesSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Languages", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10.0),
              child: pw.Text("${data['language']} - ${data['level']}",
                  style: sectionTextFontStyle));
        }).toList(),
      ],
    );
  }

  pw.Widget _buildInterestsSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Interests", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10.0),
              child: pw.Text(data['interest'], style: sectionTextFontStyle));
        }).toList(),
      ],
    );
  }

  pw.Widget _buildSkillsSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Skills", style: sectionHeaderFontStyle),
        pw.Row(children: [
          ...docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return pw.Column(children: [
              pw.Container(
                  margin: const pw.EdgeInsets.all(15.0),
                  padding: const pw.EdgeInsets.all(3.0),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(data['skill'], style: sectionTextFontStyle))
            ]);
          }).toList()
        ]),
      ],
    );
  }

  pw.Widget _buildWorkExperienceSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Work Experience", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10.0),
              child: pw.Text(
                  "${data['position']} at ${data['workplace']} (${data['fromDate']} - ${data['toDate']})",
                  style: sectionTextFontStyle));
        }).toList(),
      ],
    );
  }

  pw.Widget _buildCertificatesSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Certificates", style: sectionHeaderFontStyle),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10.0),
              child: pw.Text(
                  "${data['certificate_name']} (${data['start_date']} - ${data['end_date']})",
                  style: sectionTextFontStyle));
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: cvName,
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: CustomDrawer(
        actionButtons: buildDrawerActionButtons(context, cvName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the grid
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScreenHeader(),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 210 / 297, // Spacing between rows
                children: [
                  _buildTemplateButton(
                    context,
                    "Template", // First part of the label
                    "1", // Second part of the label
                    onPressed: () => generateCvTemplate1(cvName),
                  ),
                  _buildTemplateButton(
                    context,
                    "Template",
                    "2",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Template 2 not yet implemented."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                  _buildTemplateButton(
                    context,
                    "Template",
                    "3",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Template 3 not yet implemented."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButton(
      BuildContext context,
      String label1, // Main text, e.g., "Template"
      String label2, // Secondary text, e.g., "1"
      {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlue.shade100, // Light blue background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              label2,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildScreenHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(
        Icons.document_scanner,
        color: Colors.pink[700], // Icon for education
        size: 40.0,
      ),
      const SizedBox(height: 8.0),
      Text(
        'CV Templates',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.pink[700], // Color for header
        ),
      ),
      const SizedBox(height: 16.0), // Spacing between the header and content
    ],
  );
}
