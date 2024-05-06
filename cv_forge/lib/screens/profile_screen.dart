import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cv_forge/widgets/custom_app_bar.dart';
import 'package:cv_forge/widgets/custom_drawer.dart';
import 'package:cv_forge/utils/drawer_action_buttons.dart';
import 'package:cv_forge/screens/contact_me_screen.dart';
import 'dart:async'; // for Timer
import 'package:permission_handler/permission_handler.dart'; // for permissions

class ProfileScreen extends StatefulWidget {
  final String cvName;

  ProfileScreen({required this.cvName});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late CollectionReference profileCollection;
  File? _profileImage;
  Widget? _profilePic;
  late TextEditingController _nameController;
  late TextEditingController _professionController;
  late FlutterSoundRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  late String? _audioURL;
  bool _isRecording = false;
  bool _hasRecorded = false;
  late String _audioFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _savedName;
  String? _savedProfession;
  String? _savedAudioDuration; // To store the duration from Firebase

  @override
  void initState() {
    super.initState();
    var userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    profileCollection =
        userDoc.collection('cvs').doc(widget.cvName).collection('profile');

    _profileImage = null;
    _profilePic = null;
    _nameController = TextEditingController();
    _professionController = TextEditingController();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = AudioPlayer();
    _audioFilePath = '';

    loadProfilePictureAndAudio(); // Load data on initialization
  }

  void loadProfilePictureAndAudio() async {
    try {
      // Load the profile image
      var uploadedProfile =
          FirebaseStorage.instance.ref('profile_images/${widget.cvName}');

      var imageLink = await uploadedProfile.getDownloadURL();

      setState(() {
        _profilePic = Image.network(imageLink);
      });
    } catch (_) {}

    try {
      // Load the audio file and its duration
      var uploadedAudio =
          FirebaseStorage.instance.ref('audio_pitches/${widget.cvName}');

      var audioLink = await uploadedAudio.getDownloadURL();

      setState(() {
        _audioURL = audioLink;
        _hasRecorded = true;
      });

      var profileDoc = await profileCollection.doc('main').get();

      if (profileDoc.exists) {
        var data = profileDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          _nameController.text = data['name'] ?? ''; // Retrieve the name
          _professionController.text =
              data['profession'] ?? ''; // Retrieve the profession
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _chooseProfileImage() async {
    final status =
        await Permission.storage.request(); // Request storage permission
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profilePic = Image.file(_profileImage!);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to choose an image.'),
        ),
      );
    }
  }

  Future<void> _captureProfileImage() async {
    final status =
        await Permission.camera.request(); // Request camera permission
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profilePic = Image.file(_profileImage!);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to capture an image.'),
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    final status =
        await Permission.microphone.request(); // Request microphone permission
    if (status.isGranted) {
      Directory tempDir = await getTemporaryDirectory();
      _audioFilePath = '${tempDir.path}/pitch.wav';

      try {
        await _audioRecorder.openRecorder(); // Open the recorder
        await _audioRecorder.startRecorder(toFile: _audioFilePath);

        _recordDuration = Duration.zero;
        _recordTimer =
            Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          setState(() {
            _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
          });
        });

        setState(() {
          _isRecording = true;
          _hasRecorded = false;
        });
      } catch (e) {
        print("Failed to start recording: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Microphone permission is required to start recording.'),
        ),
      );
    }
  }

  void _stopRecording() async {
    await _audioRecorder.stopRecorder();
    _recordTimer?.cancel();

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  Future<void> _playRecording() async {
    if (_audioFilePath.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath));
    } else if (_audioURL != null) {
      await _audioPlayer.play(UrlSource(_audioURL!));
    }
  }

  Future<void> _deleteRecording() async {
    if (_audioFilePath.isNotEmpty) {
      var file = File(_audioFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await FirebaseStorage.instance
        .ref('audio_pitches/${widget.cvName}')
        .delete();

    setState(() {
      _audioFilePath = '';
      _recordDuration = Duration.zero;
      _hasRecorded = false;
    });
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage != null) {
      final storageRef =
          FirebaseStorage.instance.ref('profile_images/${widget.cvName}');
      await storageRef.putFile(_profileImage!);
    }
  }

  Future<void> _uploadAudioFile() async {
    if (_audioFilePath.isNotEmpty) {
      final storageRef =
          FirebaseStorage.instance.ref('audio_pitches/${widget.cvName}');
      await storageRef.putFile(File(_audioFilePath));
    }
  }

  Future<void> _saveProfile() async {
    await _uploadProfileImage();
    await _uploadAudioFile();

    await profileCollection.doc('main').set({
      'profile_image': _profileImage?.path ?? '',
      'name': _nameController.text,
      'profession': _professionController.text,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScreenHeader(),
            _buildProfileImageField(),
            if (_savedName != null)
              Text(
                'Name: $_savedName', // Display the saved name
                style: const TextStyle(fontSize: 16),
              ),
            if (_savedProfession != null)
              Text(
                'Profession: $_savedProfession', // Display the saved profession
                style: const TextStyle(fontSize: 16),
              ),
            _buildNameField(),
            _buildProfessionField(),
            _buildAudioPitchField(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _saveProfile();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactMeScreen(cvName: widget.cvName),
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
          Icons.person,
          color: Colors.teal[700],
          size: 40,
        ),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileImageField() {
    return Column(
      children: [
        Container(
          height: 150,
          width: 107, // Smaller size to avoid overflow
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[300],
          ),
          child: _profilePic == null
              ? Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _profilePic,
                ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _chooseProfileImage,
              icon: const Icon(Icons.image),
              label: const Text("Choose Image"),
            ),
            ElevatedButton.icon(
              onPressed: _captureProfileImage,
              icon: const Icon(Icons.camera),
              label: const Text("Take Photo"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Name',
          prefixIcon: const Icon(Icons.person),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _professionController,
        decoration: InputDecoration(
          labelText: 'Profession',
          prefixIcon: const Icon(Icons.work),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPitchField() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "Give a Short and Engaging Pitch About Yourself!",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isRecording
                  ? IconButton(
                      icon: const Icon(Icons.stop, color: Colors.red),
                      onPressed: _stopRecording,
                    )
                  : IconButton(
                      icon: const Icon(Icons.mic, color: Colors.teal),
                      onPressed: _startRecording,
                    ),
              if (_isRecording)
                Text(_formatDuration(_recordDuration)), // Display duration
              if (_hasRecorded)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: _playRecording,
                ),
              if (_hasRecorded)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _showDeleteConfirmation,
                ),
            ],
          ),
        ),
        if (_savedAudioDuration != null && !_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Duration: $_savedAudioDuration', // Show the saved duration
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Recording"),
          content:
              const Text("Are you sure you want to delete this recording?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteRecording();
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n >= 10 ? '$n' : '0$n';
    String twoDigitMinutes = twoDigits((duration.inMinutes) % 60);
    String twoDigitSeconds = twoDigits((duration.inSeconds) % 60);
    return "$twoDigitMinutes:$twoDigitSeconds"; // Correct variable names
  }
}
