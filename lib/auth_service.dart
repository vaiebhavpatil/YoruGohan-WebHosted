import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize GoogleSignIn with the client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '360774236322-79amcbsebqkae2gp2liee9rpjpnf5vbq.apps.googleusercontent.com', // Replace with your new client ID
  );

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the authentication details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential using the Google Auth token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fetch username from Firestore
  Future<String?> getUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // If the document exists, return the username
        if (userDoc.exists) {
          return userDoc[
              'username']; // Assuming username is stored in 'username' field
        } else {
          return null; // Document doesn't exist
        }
      } catch (e) {
        print("Error fetching username: $e");
        return null;
      }
    }
    return null; // User is not signed in
  }
}
