import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart'; // Import the AuthService class for Google Sign-In

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;

  // Flag to track Google sign-in progress
  bool _isGoogleSignInInProgress = false;

  // Method to validate email format
  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$")
        .hasMatch(email);
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      if (!_isEmailValid(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Please enter a valid email."),
          ));
        }
        return;
      }
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/order'); // Navigate to Order Screen
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        if (e is FirebaseAuthException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Firebase error: ${e.message}"),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("An unexpected error occurred. Please try again."),
          ));
        }
      }
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      if (!_isEmailValid(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Please enter a valid email."),
          ));
        }
        return;
      }
      if (password.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Password must be at least 6 characters long."),
          ));
        }
        return;
      }
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/order'); // Navigate to Order Screen
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        if (e is FirebaseAuthException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Firebase error: ${e.message}"),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("An unexpected error occurred. Please try again."),
          ));
        }
      }
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
        // Check if widget is still mounted before using context
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, '/order'); // Navigate to Order Screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Google sign-in failed. Please try again."),
          ));
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error signing in with Google: $e"),
        ));
      }
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
                    signUp(email, password); // Sign up if _isSignUp is true
                  } else {
                    signIn(email, password); // Log in if _isSignUp is false
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
            // Google Sign-In Button
            ElevatedButton(
              onPressed: _isGoogleSignInInProgress ? null : signInWithGoogle,
              child: _isGoogleSignInInProgress
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Sign in with Google'),
            ),
            SizedBox(height: 10),
            // Toggle between login and sign-up
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp; // Toggle the form
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
