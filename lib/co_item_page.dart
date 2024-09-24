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

  const COItemPage({
    super.key,
    required this.id,
    required this.username,
    required this.fullName,
    required this.password,
    required this.role,
  });

  @override
  State<COItemPage> createState() => _COItemPage();
}

class _COItemPage extends State<COItemPage> {
  final TextEditingController faultDescriptionController = TextEditingController();
  List<Map<String, dynamic>> _sites = []; // To hold both siteId and siteName
  List<dynamic> _supervisors = [];
  String? _selectedSite;
  bool _spareRequired = false;
  bool _cashRequired = false;
  XFile? _image;
  int? _tglAssigneeId; // Specifically for the TGL
  int? _rmAssigneeId;  // Specifically for the RM

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchAssignedSites();
    fetchAllSupervisors();
  }

  // Fetch all supervisors of the user and assign TGL and RM accordingly
  Future<void> fetchAllSupervisors() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    try {
      var response = await http.get(
        Uri.parse('http://192.168.32.157:8080/api/user/supervisors'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        print('Supervisors fetched: $data');

        setState(() {
          _supervisors = data;
          _tglAssigneeId = _supervisors.firstWhere(
            (supervisor) => supervisor['role'] == 'TGL',
            orElse: () => null,
          )['id']; // Assign TGL's ID

          _rmAssigneeId = _supervisors.firstWhere(
            (supervisor) => supervisor['role'] == 'RM',
            orElse: () => null,
          )['id']; // Assign RM's ID
        });
        print('TGL Assignee ID: $_tglAssigneeId');
        print('RM Assignee ID: $_rmAssigneeId');
      } else {
        print('Error fetching supervisors: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch assigned sites
  Future<void> fetchAssignedSites() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    var request = http.Request('GET', Uri.parse('http://192.168.32.157:8080/api/user/sites'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Sites fetched: $responseBody');

        List<dynamic> sites = json.decode(responseBody);
        setState(() {
          // Update the _sites list with both siteId and siteName
          _sites = List<Map<String, dynamic>>.from(sites.map((site) => {
                'siteId': site['siteId'],
                'siteName': site['siteName'],
              }));
        });
      } else {
        print('Error fetching sites: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = pickedImage;
    });
  }

  // Submit the request and forward it to the TGL and next to the RM
  void _submitForm() async {
    if (_tglAssigneeId == null || _rmAssigneeId == null) {
      print('No TGL or RM assigned');
      return;
    }

    String faultDescription = faultDescriptionController.text.isNotEmpty
        ? faultDescriptionController.text
        : "No description provided";
    String status = "PENDING";
    String type = _cashRequired ? "CASH" : "SPARE";
    String imagePath = _image != null ? _image!.path : '';
    int userId = widget.id;

    // Get the selected site's siteId
    int? siteId = _selectedSite != null
        ? _sites.firstWhere((site) => site['siteName'] == _selectedSite)['siteId']
        : null;

    if (siteId == null) {
      print('No site selected');
      return;
    }

    var requestBody = jsonEncode({
      "faultDescription": faultDescription,
      "status": status,
      "type": type,
      "imagePath": imagePath,
      "currentLevel": 'TGL',
      "userId": userId,
      "siteId": siteId, // Use the correct siteId
      "forwardTo": _tglAssigneeId,  // Forward to TGL
      "forwardedBy": userId,
      "nextAssignee": _rmAssigneeId // Next assignee is RM
    });

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      var response = await http.post(
        Uri.parse('http://192.168.32.157:8080/api/request'),
        headers: headers,
        body: requestBody,
      );

      // Log the full response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Request submitted successfully');
      } else {
        print('Error submitting request: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
                value: _selectedSite != null && _sites.any((site) => site['siteName'] == _selectedSite)
                    ? _selectedSite
                    : null, // Ensure the selected value is in the dropdown list
                items: _sites.map((site) => DropdownMenuItem<String>(
                      value: site['siteName'],  // Match exactly to the site name
                      child: Text(site['siteName']),
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
              controller: faultDescriptionController,
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
