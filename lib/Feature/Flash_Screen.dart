import 'package:flutter/material.dart';
import 'package:gift_shop/Authentication/Login.dart'; // Import login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginScreen()), // 'const' for consistency
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Set background color for the splash screen
      body: Center(
        child: Image.asset(
          'assets/Logo.png', // Replace with your image path
          width: 400,
          height: 400,
        ),
      ),
    );
  }
}
