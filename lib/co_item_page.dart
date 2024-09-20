import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class COItemPage extends StatefulWidget {
  final int id;
  final String username;
  final String fullName;
  final String password;
  final String role;
  const COItemPage({super.key, required this.id, required this.username, required this.fullName, required this.password, required this.role});

  @override
  State<COItemPage> createState() => _COItemPage();
}

class _COItemPage extends State<COItemPage> {
  List<String> _sites = [];
  String? _selectedSite;
  bool _spareRequired = false;
  bool _cashRequired = false;
  XFile? _image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchAssignedSites();
  }

  Future<void> fetchAssignedSites() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,  // Corrected passing of Basic Auth
    };

    var request = http.Request('GET', Uri.parse('http://192.168.225.166:8080/api/user/sites'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Sites fetched: $responseBody');  // Debug output

        List<dynamic> sites = json.decode(responseBody);
        setState(() {
          _sites = List<String>.from(sites.map((site) => site['siteName'].toString()));  // Update dropdown list
        });
      } else {
        print('Error fetching sites: ${response.reasonPhrase}');  // Debug error
      }
    } catch (e) {
      print('Error: $e');  // Debug exception
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = pickedImage;
    });
  }

  void _submitForm() {
    // Perform your form submission logic here
    print('Form Submitted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO Dashboard', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site ID Dropdown populated with fetched sites
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Site ID',
                border: OutlineInputBorder(),
              ),
              value: _selectedSite,
              items: _sites.map((site) => DropdownMenuItem<String>(
                    value: site,
                    child: Text(site),
                  )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSite = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Fault Nature Text Field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fault Nature',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Evidence Section (Image Picker)
            const Text(
              'Evidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey[700],
                      ),
                    )
                  : Image.file(
                      File(_image!.path),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),

            // Spare Required Checkbox
            CheckboxListTile(
              title: const Text('Spare Required'),
              value: _spareRequired,
              onChanged: (bool? value) {
                setState(() {
                  _spareRequired = value ?? false;
                });
              },
            ),

            // Cash Required Checkbox
            CheckboxListTile(
              title: const Text('Cash Required'),
              value: _cashRequired,
              onChanged: (bool? value) {
                setState(() {
                  _cashRequired = value ?? false;
                });
              },
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
