import 'package:flutter/material.dart';
import 'package:telecom_app/dashboard.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
// Controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 30),
              // Logo
              // Image.asset(
              //   'assets/images/logo.jpg', // Update with your logo path
              //   height: 100,
              // ),
              const SizedBox(height: 10),
              // Subtitle
              const Text(
                'ITSM ZONG',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // Login Title
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              // Login Subtitle
              const Text(
                'Login now to access your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // Username TextField
              TextFormField(
                controller: usernameController,
                
                decoration: const InputDecoration(
                  labelText: 'Username or Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // Password TextField
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.visibility),
                ),
              ),
              const SizedBox(height: 20),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add your login logic here
                    if ((usernameController.text == 'co@admin.com' ||
                        usernameController.text == 'tgl@admin.com' ||
                        usernameController.text == 'rm@admin.com' ||
                        usernameController.text == 'pm@admin.com') &&
                        passwordController.text == 'admin') {
                        // Navigate to the Dashboard if the credentials are correct
                        Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => DashboardPage(username: usernameController.text))
                        );
                      }
                    else {
                      // Show error message if credentials are incorrect
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text('Invalid username or password'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    
                    
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button background color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}