import 'package:flutter/material.dart';
import 'dart:async';
import 'package:telecom_app/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50], // Set the background color
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image for the logo
            // Image.asset(
            //   'assets/images/logo.jpg', // Make sure to place your logo image in this path
            //   height: 100,
            // ),
            SizedBox(height: 20),
            // Title and subtitle text
            Text(
              'A leading Provider of Infrastructure Solution',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Global picture, Local insights',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Illustration image
            // Image.asset(
            //   'assets/images/illustration.jpg', // Make sure to place your illustration image in this path
            //   height: 200,
            // ),
            SizedBox(height: 20),
            CircularProgressIndicator(), // Loading indicator
          ],
        ),
      ),
    );
  }
}
