import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import '../browse_posts_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, show browse posts screen
        if (snapshot.hasData && snapshot.data != null) {
          print('User logged in: ${snapshot.data!.email}');
          return const BrowsePostsScreen();
        }
        
        // Otherwise show sign in screen
        print('No user logged in, showing sign in screen');
        return const SignInScreen();
      },
    );
  }
}