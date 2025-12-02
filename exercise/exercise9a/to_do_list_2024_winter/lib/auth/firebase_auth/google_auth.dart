import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

final _googleSignIn = google_sign_in.GoogleSignIn(
  scopes: <String>['email'],
);

Future<UserCredential?> googleSignInFunc() async {
  if (kIsWeb) {
    return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  await signOutWithGoogle().catchError((_) => null);
  
  final google_sign_in.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) {
    return null;
  }
  
  final google_sign_in.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: googleAuth.accessToken,
  );
  
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

Future signOutWithGoogle() => _googleSignIn.signOut();