import 'package:flutter/material.dart';
import 'package:cv_forge/screens/home_screen.dart';
import 'package:cv_forge/screens/profile_screen.dart';
import 'package:cv_forge/screens/contact_info_screen.dart';
import 'package:cv_forge/screens/education_screen.dart';
import 'package:cv_forge/screens/skills_screen.dart';
import 'package:cv_forge/screens/personal_projects_screen.dart';
import 'package:cv_forge/screens/work_experience_screen.dart';
import 'package:cv_forge/screens/certificates_screen.dart';
import 'package:cv_forge/screens/languages_and_interests_screen.dart';
import 'package:cv_forge/screens/cv_templates_screen.dart';

List<Widget> buildDrawerActionButtons(BuildContext context, String cvName) {
  return [
    _buildCustomTile(
      context,
      icon: Icons.person,
      text: 'Profile',
      backgroundColor: Colors.teal[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10), // Spacing between ListTiles
    _buildCustomTile(
      context,
      icon: Icons.contact_mail,
      text: 'Contact Info',
      backgroundColor: Colors.deepOrange[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ContactInfoScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.school,
      text: 'Education',
      backgroundColor: Colors.purple[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => EducationScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.construction,
      text: 'Skills',
      backgroundColor: Colors.green[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SkillsScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.book,
      text: 'Personal Projects',
      backgroundColor: Colors.brown[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PersonalProjectsScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.business_center,
      text: 'Work Experience',
      backgroundColor: Colors.indigo[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => WorkExperienceScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.verified,
      text: 'Certificates',
      backgroundColor: Colors.red[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CertificatesScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.language,
      text: 'Languages & Interests',
      backgroundColor: Colors.cyan[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  LanguagesAndInterestsScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.document_scanner,
      text: 'CV Templates',
      backgroundColor: Colors.pink[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CVTemplatesScreen(cvName: cvName)),
        );
      },
    ),
    const SizedBox(height: 10),
    _buildCustomTile(
      context,
      icon: Icons.home,
      text: 'Home',
      backgroundColor: Colors.blue[700],
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      },
    ),
  ];
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
