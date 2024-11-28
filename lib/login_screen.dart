import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isGoogleSignInInProgress = false;

  // Method to validate email format
  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$")
        .hasMatch(email);
  }

  // Function to handle navigation based on the role
  void _navigateBasedOnRole(String role) {
    if (role == 'worker') {
      Navigator.pushReplacementNamed(context, '/kitchen');
    } else {
      Navigator.pushReplacementNamed(context, '/order');
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      if (!_isEmailValid(email)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please enter a valid email."),
        ));
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Retrieve user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'name': userCredential.user!.displayName ?? 'Unknown',
          'role': 'user',
        });
      }

      String role = userDoc['role'] ?? 'user';
      _navigateBasedOnRole(role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
      ));
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      if (!_isEmailValid(email)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please enter a valid email."),
        ));
        return;
      }

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password must be at least 6 characters long."),
        ));
        return;
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate based on role after sign-up
      String role = 'user'; // default role for new users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'name': userCredential.user!.displayName ?? 'Unknown',
        'role': role,
      });

      _navigateBasedOnRole(role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
      ));
    }
  }

  // Google Sign-In method
  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        _isGoogleSignInInProgress = true;
      });

      User? user = await AuthService().signInWithGoogle();
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email ?? '',
            'name': user.displayName ?? 'Unknown',
            'role': 'user',
          });
        }

        String role = userDoc['role'] ?? 'user';
        _navigateBasedOnRole(role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Google sign-in failed. Please try again."),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error signing in with Google: $e"),
      ));
    } finally {
      setState(() {
        _isGoogleSignInInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  if (_isSignUp) {
                    signUp(email, password);
                  } else {
                    signIn(email, password);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Please fill in both email and password."),
                  ));
                }
              },
              child: Text(_isSignUp ? 'Sign Up' : 'Log In'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isGoogleSignInInProgress ? null : signInWithGoogle,
              child: _isGoogleSignInInProgress
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Sign in with Google'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
              child: Text(_isSignUp
                  ? 'Already have an account? Log in'
                  : 'Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
