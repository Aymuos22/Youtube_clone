import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User? user;
  final String userDescription; // New field for user description

  const ProfilePage({
    Key? key,
    required this.user,
    this.userDescription =
        'No description', // Default value for user description
  }) : super(key: key);

  String getUserName(User? user) {
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return user.displayName!;
    } else {
      return 'No username';
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter =
        user!.displayName != null && user!.displayName!.isNotEmpty
            ? user!.displayName![0].toUpperCase()
            : 'U'; // Default letter 'U' if no username

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.red, // Set app bar color to red
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50,
              backgroundColor:
                  Colors.blue, // Set background color for the avatar
              child: Text(
                firstLetter,
                style: TextStyle(
                    fontSize: 40, color: Colors.white), // Style for the letter
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Username: ${user!.displayName ?? 'No username'}',
              style: TextStyle(
                  fontSize: 20, color: Colors.black), // Set text color to black
            ),
            SizedBox(height: 10),
            Text(
              'Description: $userDescription',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors
                      .black54), // Set text color to a lighter shade of black
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(user: user),
                  ),
                );
              },
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final User? user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user!.displayName ?? '');
    _descriptionController =
        TextEditingController(text: widget.user!.photoURL ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _updateProfile();
                Navigator.pop(context); // Go back to profile page
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    try {
      await widget.user!.updateProfile(
        displayName: _usernameController.text,
        photoURL: _descriptionController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
