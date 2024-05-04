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

  const CVTemplatesScreen({super.key, required this.cvName});

  Future<File> generateCvTemplate1(String cvName) async {
    final pdf = pw.Document();

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
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null)
                    pw.Image(profileImage, height: 100, width: 100),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileDoc.exists)
                    pw.Text(
                      profileDoc.data()?['name'] ?? '',
                      style: pw.TextStyle(fontSize: 24),
                    ),
                  if (profileDoc.exists)
                    pw.Text(profileDoc.data()?['profession'] ?? ''),
                ],
              ),
            ],
          ));

          // Solid line
          content.add(pw.Divider());

          // Second row with phone, address, and links
          content.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (contactInfoDoc.exists &&
                  contactInfoDoc.data()?['phone'] != null)
                pw.Text("Phone: ${contactInfoDoc.data()?['phone']}"),
              if (contactInfoDoc.exists &&
                  contactInfoDoc.data()?['address'] != null)
                pw.Text("Address: ${contactInfoDoc.data()?['address']}"),
              if (links.docs.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: links.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return pw.Text(
                      "Link: ${data['social_media_link']}",
                      style: pw.TextStyle(
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
                      _buildPersonalProjectsSection(personalProjects.docs),
                      _buildLanguagesSection(languages.docs),
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
                      _buildWorkExperienceSection(workExperience.docs),
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
        pw.Text("Education",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(
              "${data['studyProgram']} at ${data['placeOfEducation']} (${data['fromDate']} - ${data['toDate']})");
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
        pw.Text("Personal Projects",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(
              "${data['projectName']} (${data['fromDate']} - ${data['toDate']}) - ${data['description']}");
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
        pw.Text("Languages",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text("${data['language']} - ${data['level']}");
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
        pw.Text("Interests",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(data['interest']);
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
        pw.Text("Skills", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(data['skill']);
        }).toList(),
      ],
    );
  }

  pw.Widget _buildWorkExperienceSection(List<DocumentSnapshot> docs) {
    if (docs.isEmpty)
      return pw.Container(); // Return empty container if no data
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Work Experience",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(
              "${data['position']} at ${data['workplace']} (${data['fromDate']} - ${data['toDate']})");
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
        pw.Text("Certificates",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Text(
              "${data['certificate_name']} (${data['start_date']} - ${data['end_date']})");
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => generateCvTemplate1(cvName),
              child: Text("Generate Template 1"),
            ),
            ElevatedButton(
              onPressed: () {
                // Placeholder for template 2
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Template 2 not yet implemented."),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text("Generate Template 2"),
            ),
          ],
        ),
      ),
    );
  }
}
