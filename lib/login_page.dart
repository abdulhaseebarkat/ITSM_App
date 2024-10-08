import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telecom_app/dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
  // Base64 encode for Basic Authentication (if needed)
  String basicAuth = 'Basic ' + base64Encode(utf8.encode('${usernameController.text}:${passwordController.text}'));

  var headers = {
    'Content-Type': 'application/json',
    'Authorization': basicAuth // Update the authorization header here
  };
  var request = http.Request(
    'POST',
    Uri.parse('http://192.168.89.106:8080/public/api/auth/login'),
  );

  // Request body with credentials
  request.body = json.encode({
    "email": usernameController.text,
    "password": passwordController.text
  });
  request.headers.addAll(headers);

  try {
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      // Successful login
      var responseBody = await response.stream.bytesToString();
      print('Login successful: $responseBody');
      
      // Decode the JSON response
      var data = json.decode(responseBody);
      
      // Extract information from the JSON response
      int id = data['id'];
      String fullName = data['fullName'];
      String email = data['email'];
      String role = data['role'];
      // Print extracted information (optional for debugging)
      print('ID: $id');
      print('Full Name: $fullName');
      print('Email: $email');
      print('Role: $role');

      // Navigate to DashboardPage and pass the data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            id: id,
            username: usernameController.text, 
            fullName: fullName, 
            role: role,
            password: passwordController.text,
          ),
        ),
      );
    } else {
      // Invalid login credentials
      print('Error: ${response.reasonPhrase}');
      _showErrorDialog('Invalid username or password');
    }
  } catch (e) {
    // Handle connection errors
    print('Error: $e');
    _showErrorDialog('Error connecting to the server $e');
  }
}


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
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
                  onPressed: _login,
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
