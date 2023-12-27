import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_post/VideoPlay.dart';
import 'package:video_post/profile.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class VideoList extends StatefulWidget {
  @override
  _VideoListState createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  late TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _videoStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _username = '_';
  late User? user; // Define User? user to hold the current user information

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Call the method to fetch user details
    _videoStream = FirebaseFirestore.instance.collection('videos').snapshots();
  }

  Future<void> _initializeUser() async {
    user = _auth.currentUser;

    if (user != null) {
      await user!.reload();
      user = _auth.currentUser;

      setState(() {
        _username = user?.displayName ?? ''; // Assign the fetched username
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: const Color.fromARGB(221, 11, 11, 11),
        textTheme: TextTheme(
          headline6: TextStyle(color: Colors.white), // For AppBar title
          bodyText1:
              TextStyle(color: Colors.white), // For ListTile title and subtitle
          bodyText2: TextStyle(color: Colors.white), // For TextField
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
            ),
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _videoStream = FirebaseFirestore.instance
                    .collection('videos')
                    .where('title', isGreaterThanOrEqualTo: value)
                    .where('title', isLessThan: value + 'z')
                    .snapshots();
              });
            },
          ),
          backgroundColor: Colors.red,
          actions: [
            IconButton(
              onPressed: () {
                // Define the action when the button is pressed
              },
              icon: Icon(Icons.live_tv),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.red,
                ),
                child: Row(
                  children: [
                    FutureBuilder<String?>(
                      future: fetchUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          String? username = snapshot.data;
                          String initial = username != null &&
                                  username.isNotEmpty
                              ? username[0].toUpperCase()
                              : 'U'; // Default letter in case of empty username

                          return CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else {
                          return CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(width: 10),
                    Text(
                      '$_username',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Profile'),
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(user: user!),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: Text('Log Out'),
                onTap: () => _signOut(context),
              ),
              ListTile(
                title: Text('Exit'),
                onTap: () {
                  exit(0);
                },
              ),
              // Add more list items as needed
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _videoStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            List<DocumentSnapshot> videos = snapshot.data!.docs;

            return ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> videoData =
                    videos[index].data() as Map<String, dynamic>;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Card(
                    elevation: 4,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      leading: FutureBuilder<Widget>(
                        future: _getVideoThumbnail(videoData['videoUrl'] ?? ''),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Icon(Icons.error_outline);
                          } else {
                            return snapshot.data ??
                                Container(); // Display the thumbnail or empty Container
                          }
                        },
                      ),
                      title: Text(
                        videoData['title'] ?? '',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        videoData['category'] ?? '',
                        style: TextStyle(fontSize: 14),
                      ),
                      tileColor: Color.fromARGB(255, 242, 141, 141),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlay(
                              videoUrl: videoData['videoUrl'] ?? '',
                              videoId: videoData['videoId'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/upload');
              },
              child: Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<Widget> _getVideoThumbnail(String videoUrl) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      quality: 25,
    );

    return uint8list != null
        ? Image.memory(
            uint8list,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          )
        : Icon(Icons.error_outline);
  }

  Future<String?> fetchUserName() async {
    User? user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      user = _auth.currentUser;

      return user?.displayName ?? '';
    }
    return null;
  }
}
