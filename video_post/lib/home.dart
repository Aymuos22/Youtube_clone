import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Auth/signin.dart';
import 'package:video_post/VideoList.dart';

class Home extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!.emailVerified) {
              return VideoList();
            } else {
              // User is not email verified, show verification page or handle accordingly
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Please verify your email to access the content.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInPage(),
                            ),
                          );
                        },
                        child: Text('Return to Sign In'),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            return SignInPage();
          }
        }
      },
    );
  }
}
