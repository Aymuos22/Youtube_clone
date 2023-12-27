import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:video_post/VideoList.dart';

class VideoUploadScreen extends StatefulWidget {
  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  late File _videoFile;
  String _title = '';
  String _description = '';
  String _category = '';
  late Position _currentPosition;
  String _status = 'Upload';

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _videoFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadVideo() async {
    try {
      setState(() {
        _status = 'Uploading...';
      });
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child('video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final UploadTask uploadTask = storageRef.putFile(_videoFile);

      await uploadTask.whenComplete(() {
        print('Video uploaded');
      });

      final String videoUrl = await storageRef.getDownloadURL();
      print('Video URL: $videoUrl');

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String videoId =
          storageRef.fullPath.split('/').last.split('.').first;

      await firestore.collection('videos').doc(videoId).set({
        'title': _title,
        'description': _description,
        'category': _category,
        'videoUrl': videoUrl,
        'latitude': _currentPosition.latitude,
        'longitude': _currentPosition.longitude,
        'videoId': videoId, // Add the videoId field in Firestore
      });

      print('Metadata uploaded to Firestore');
      setState(() {
        _status = 'Uploaded';
      });
    } catch (e) {
      print('Error uploading video: $e');
      setState(() {
        _status = 'Error';
      });
    }
    if (_status == 'Uploaded') {
      Navigator.pushNamed(context, '/');
    }
  }

  Future<void> _getLocation() async {
    try {
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnabled) {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } else {
        bool locationStatus = await Geolocator.openLocationSettings();
        if (locationStatus) {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } else {
          // User denied enabling location, handle accordingly
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      // Handle error fetching location here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Video'),
        backgroundColor: Colors.red,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.red, // Set primary color to red
            colorScheme: ColorScheme.dark(
              secondary: Color.fromARGB(
                  255, 255, 255, 255), // Use dark gray for secondary color
            ),
            textTheme: TextTheme(
              bodyText1:
                  TextStyle(color: Colors.white), // Set text color to white
              bodyText2:
                  TextStyle(color: Colors.white), // Set text color to white
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _pickVideo,
                  child:
                      Text('Pick Video', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                    onPressed: _pickVideo, child: Icon(Icons.camera_enhance)),
                SizedBox(height: 20.0),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _title = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.black), // Set outline color to black
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _description = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.black), // Set outline color to black
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                DropdownButtonFormField<String>(
                  value: _category.isNotEmpty ? _category : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      _category = newValue ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black, // Set outline color to black
                      ),
                    ),
                  ),
                  items: [
                    'Sports',
                    'Music',
                    'Education',
                    'Review',
                    'Reaction',
                    'Animated',
                    'Travel',
                    'Comedy',
                    'Parody',
                    'ASMR',
                    'wildlife',
                    'Gaming',
                    'News',
                    'Politics',
                    'Fitness'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.0),
                Text(_status, style: TextStyle(color: Colors.white)),
                ElevatedButton(
                  onPressed: () async {
                    await _getLocation();
                    await _uploadVideo();
                  },
                  child: Text('Upload', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
