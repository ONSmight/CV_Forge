import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/education_screen.dart';

class ContactMeScreen extends StatefulWidget {
  final String cvName;

  ContactMeScreen({required this.cvName});

  @override
  _ContactMeScreenState createState() => _ContactMeScreenState();
}

class _ContactMeScreenState extends State<ContactMeScreen> {
  late CollectionReference contactCollection;
  late CollectionReference linksCollection;

  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    contactCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('contact');
    linksCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('links');
    phoneController = TextEditingController();
    addressController = TextEditingController();
    _loadContactInfo();
  }

  void _saveContactInfo() async {
    await contactCollection.doc('info').set({
      'phone': phoneController.text,
      'address': addressController.text,
    });
  }

  void _loadContactInfo() async {
    var contactInfoDoc = await contactCollection.doc('info').get();

    if (contactInfoDoc.exists) {
      var data = contactInfoDoc.data() as Map<String, dynamic>;

      phoneController.text = data['phone'] ?? '';
      addressController.text = data['address'] ?? '';
    }
  }

  void _addSocialMediaLink(String link) {
    linksCollection.add({'social_media_link': link});
  }

  void _editSocialMediaLink(String docId, String newLink) {
    linksCollection.doc(docId).update({'social_media_link': newLink});
  }

  void _deleteSocialMediaLink(String docId) {
    linksCollection.doc(docId).delete();
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
            _buildPhoneField(phoneController),
            _buildAddressField(addressController),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: linksCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var links = snapshot.data!.docs.toList();

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          var link = links[index];
                          var socialLink = link['social_media_link'];
                          var controller =
                              TextEditingController(text: socialLink);

                          return Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (newValue) =>
                                        _editSocialMediaLink(link.id, newValue),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _deleteSocialMediaLink(link.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildAddSocialMediaButton(
                          context), // Place the button at the bottom
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _saveContactInfo();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EducationScreen(cvName: widget.cvName),
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
          Icons.contact_mail,
          color: Colors.deepOrange[700],
          size: 40.0,
        ),
        const Text(
          'Contact Me',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildPhoneField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Address',
          prefixIcon: Icon(Icons.home),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildAddSocialMediaButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all(Colors.deepOrange.shade700),
        ),
        onPressed: () => _showAddSocialMediaLinkDialog(context),
        child: const Text(
          "Add Social Media Link",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddSocialMediaLinkDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Social Media Link'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter social media link',
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
                var newLink = controller.text.trim();
                if (newLink.isNotEmpty) {
                  _addSocialMediaLink(newLink);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill the field.'),
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
}
