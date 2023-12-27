import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_post/profile.dart';

class VideoPlay extends StatefulWidget {
  final String videoUrl;
  final String videoId;

  const VideoPlay({required this.videoUrl, required this.videoId});

  @override
  _VideoPlayState createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  late VideoPlayerController _controller;
  int likes = 0;
  int dislikes = 0;
  bool _isVideoLoading = true;
  bool _isPlaying = false;
  String? videoDescription;
  String? currentUserID;
  String? videoTitle;
  late TextEditingController _commentController;
  List<String> comments = [];
  late FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
        });
      });

    _auth = FirebaseAuth.instance;
    _fetchVideoDetails();
    _getCurrentUserID();
    fetchAndDisplayComments();
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

  Future<void> fetchAndDisplayComments() async {
    try {
      QuerySnapshot commentSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      List<String> fetchedComments = [];

      for (final doc in commentSnapshot.docs) {
        String? userId = doc.get('userId') as String?;
        String commentText = doc.get('comment') as String? ?? '';

        if (userId != null) {
          Future<String?> username = fetchUserName();

          fetchedComments.add('$username: $commentText');
        }
      }

      setState(() {
        comments = fetchedComments;
      });
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> addCommentToFirebase(String comment) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .get();
      String username = userDoc.get('displayName') ?? 'User';
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add({
        'username': username,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      fetchAndDisplayComments();
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _fetchVideoDetails() async {
    try {
      DocumentSnapshot videoSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .get();

      if (videoSnapshot.exists) {
        setState(() {
          videoTitle = videoSnapshot.get('title') ?? 'Video Title';
          likes = videoSnapshot.get('likes') ?? 0;
          dislikes = videoSnapshot.get('dislikes') ?? 0;
          videoDescription = videoSnapshot.get('description') as String?;
        });
      }
    } catch (e) {
      print('Error fetching video details: $e');
    }
  }

  void _getCurrentUserID() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          currentUserID = user.uid;
        });
      }
    });
  }

  Future<void> _likeVideo() async {
    if (currentUserID != null) {
      try {
        DocumentSnapshot likesSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(widget.videoId)
            .collection('likes')
            .doc(currentUserID)
            .get();

        if (!likesSnapshot.exists) {
          await FirebaseFirestore.instance
              .collection('videos')
              .doc(widget.videoId)
              .collection('likes')
              .doc(currentUserID)
              .set({'liked': true});

          setState(() {
            likes++;
          });
        }
      } catch (e) {
        print('Error liking video: $e');
      }
    }
  }

  Future<void> _dislikeVideo() async {
    if (currentUserID != null) {
      try {
        DocumentSnapshot dislikesSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(widget.videoId)
            .collection('dislikes')
            .doc(currentUserID)
            .get();

        if (!dislikesSnapshot.exists) {
          await FirebaseFirestore.instance
              .collection('videos')
              .doc(widget.videoId)
              .collection('dislikes')
              .doc(currentUserID)
              .set({'disliked': true});

          setState(() {
            dislikes++;
          });
        }
      } catch (e) {
        print('Error disliking video: $e');
      }
    }
  }

  Widget _buildCommentsSection() {
    return SingleChildScrollView(
      child: Container(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  String comment = comments[index];
                  List<String> commentParts = comment.split(':');
                  if (commentParts.length >= 2) {
                    String username = commentParts[0].trim();
                    String commentText =
                        commentParts.sublist(1).join(':').trim();

                    return FutureBuilder<String?>(
                      future:
                          fetchUserName(), // Call fetchUserName without arguments
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData) {
                          return ListTile(
                            title: CircularProgressIndicator(),
                          );
                        } else {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                snapshot.data![0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.data!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  commentText,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSubmitted: (comment) {
                        addCommentToFirebase(comment);
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      addCommentToFirebase(_commentController.text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(videoTitle ?? ''),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isVideoLoading)
              Container(
                  margin: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator())),
            if (!_isVideoLoading)
              Stack(alignment: Alignment.center, children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      _isPlaying ? _controller.play() : _controller.pause();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _isPlaying
                      ? SizedBox.shrink()
                      : IconButton(
                          icon: Icon(Icons.play_arrow,
                              size: 64, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isPlaying = true;
                              _controller.play();
                            });
                          },
                        ),
                )
              ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _likeVideo,
                  icon: Icon(
                    Icons.thumb_up,
                    color: Colors.blue,
                  ),
                ),
                Text('$likes'),
                SizedBox(width: 20),
                IconButton(
                  onPressed: _dislikeVideo,
                  icon: Icon(
                    Icons.thumb_down,
                    color: Colors.red,
                  ),
                ),
                Text('$dislikes'),
              ],
            ),
            if (videoDescription != null)
              Container(
                margin: EdgeInsets.all(8.0),
                child: Text(
                  'Video Description: $videoDescription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            Container(
              margin: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Comments Section',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
