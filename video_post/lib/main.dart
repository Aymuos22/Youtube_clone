import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:video_post/VideoUpload.dart';
import 'package:video_post/VideoList.dart';
import 'Auth/signin.dart';
import 'Auth/signup.dart';
import 'package:video_post/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyAbEMIMOR-uxGNoSir_GU8srWx3c2OfPgI",
        projectId: "videoapp-c3e22",
        appId: "1:405785573249:android:b07a575e965aa6277d1a80",
        messagingSenderId: "405785573249"),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video App',
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/upload': (context) => VideoUploadScreen(),
        '/list': (context) => VideoList(),
      },
    );
  }
}
