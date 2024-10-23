// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart';

// class COItemPage extends StatefulWidget {
//   final int id;
//   final String username;
//   final String fullName;
//   final String password;
//   final String role;

//   const COItemPage({
//     super.key,
//     required this.id,
//     required this.username,
//     required this.fullName,
//     required this.password,
//     required this.role,
//   });

//   @override
//   State<COItemPage> createState() => _COItemPage();
// }

// class _COItemPage extends State<COItemPage> {
//   final TextEditingController faultDescriptionController = TextEditingController();
//   List<Map<String, dynamic>> _sites = []; // To hold both siteId and siteName
//   List<dynamic> _supervisors = [];
//   String? _selectedSite;
//   bool _spareRequired = false;
//   bool _cashRequired = false;
//   List<XFile> _images = []; // To store up to four images
//   int? _tglAssigneeId; // Specifically for the TGL
//   int? _rmAssigneeId;  // Specifically for the RM

//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     fetchAssignedSites();
//     fetchAllSupervisors();
//   }

//   // Fetch all supervisors of the user and assign TGL and RM accordingly
//   Future<void> fetchAllSupervisors() async {
//     String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

//     var headers = {
//       'Authorization': basicAuth,
//     };

//     try {
//       var response = await http.get(
//         Uri.parse('http://13.49.230.203:8080/api/user/supervisors'),
//         headers: headers,
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         var data = jsonDecode(response.body);
//         print('Supervisors fetched: $data');

//         setState(() {
//           _supervisors = data;
//           _tglAssigneeId = _supervisors.firstWhere(
//             (supervisor) => supervisor['role'] == 'TGL',
//             orElse: () => null,
//           )['id']; // Assign TGL's ID

//           _rmAssigneeId = _supervisors.firstWhere(
//             (supervisor) => supervisor['role'] == 'RM',
//             orElse: () => null,
//           )['id']; // Assign RM's ID
//         });
//         print('TGL Assignee ID: $_tglAssigneeId');
//         print('RM Assignee ID: $_rmAssigneeId');
//       } else {
//         print('Error fetching supervisors: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   // Fetch assigned sites
//   Future<void> fetchAssignedSites() async {
//     String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

//     var headers = {
//       'Authorization': basicAuth,
//     };

//     var request = http.Request('GET', Uri.parse('http://13.49.230.203:8080/api/user/sites'));

//     request.headers.addAll(headers);

//     try {
//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         String responseBody = await response.stream.bytesToString();
//         print('Sites fetched: $responseBody');

//         List<dynamic> sites = json.decode(responseBody);
//         setState(() {
//           _sites = List<Map<String, dynamic>>.from(sites.map((site) => {
//                 'siteId': site['siteId'],
//                 'siteName': site['siteName'],
//               }));
//         });
//       } else {
//         print('Error fetching sites: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   Future<void> _pickImages() async {
//     if (_images.length >= 4) {
//       print('Cannot select more than 4 images');
//       return;
//     }

//     final pickedImage = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

//     if (pickedImage != null) {
//       setState(() {
//         _images.add(XFile(pickedImage.path));
//       });
//     } else {
//       print('No image selected');
//     }
//   }

//   // Submit the request and forward it to the TGL and next to the RM
//   Future<void> _submitForm() async {
//     if (_tglAssigneeId == null || _rmAssigneeId == null) {
//       print('No TGL or RM assigned');
//       return;
//     }

//     String faultDescription = faultDescriptionController.text.isNotEmpty
//         ? faultDescriptionController.text
//         : "No description provided";
//     String status = "PENDING";
//     String type = _cashRequired ? "CASH" : "SPARE";
//     int userId = widget.id;

//     // Get the selected site's siteId
//     int? siteId = _selectedSite != null
//         ? _sites.firstWhere((site) => site['siteName'] == _selectedSite)['siteId']
//         : null;

//     if (siteId == null) {
//       print('No site selected');
//       return;
//     }

//     var uri = Uri.parse('http://13.49.230.203:8080/api/request');

//     var request = http.MultipartRequest('POST', uri);

//     var requestJson = jsonEncode({
//       'faultDescription': faultDescription,
//       'status': status,
//       'type': type,
//       'currentLevel': 'TGL',
//       'userId': userId,
//       'siteId': siteId,
//       'forwardTo': _tglAssigneeId,
//       'forwardedBy': userId,
//       'nextAssignee': _rmAssigneeId
//     });

//     var requestPart = http.MultipartFile.fromString(
//       'request',
//       requestJson,
//       contentType: MediaType('application', 'json'),
//     );
//     request.files.add(requestPart);

//     // Add multiple images
//     for (var image in _images) {
//       var stream = http.ByteStream(image.openRead());
//       var length = await image.length();

//       var multipartFile = http.MultipartFile('images',
//         stream,
//         length,
//         filename: basename(image.path),
//         contentType: MediaType('image', 'jpeg'),
//       );
//       request.files.add(multipartFile);
//     }

//     String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
//     request.headers['Authorization'] = basicAuth;

//     try {
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);
//       if (response.statusCode == 201) {
//         print('Uploaded successfully!');
//       } else {
//         print('Failed to upload. Status code: ${response.statusCode}');
//         print('Response body: ${response.body}');
//       }
//     } catch (e) {
//       print('Error occurred: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('CO Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
//         centerTitle: false,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: 'Site ID',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _selectedSite != null && _sites.any((site) => site['siteName'] == _selectedSite)
//                     ? _selectedSite
//                     : null,
//                 items: _sites.map((site) => DropdownMenuItem<String>(
//                       value: site['siteName'],
//                       child: Text(site['siteName']),
//                     )).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedSite = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: faultDescriptionController,
//                 decoration: const InputDecoration(
//                   labelText: 'Fault Nature',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text('Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               GestureDetector(
//                 onTap: _pickImages,
//                 child: Container(
//                   height: 150,
//                   color: Colors.grey[300],
//                   child: GridView.builder(
//                     itemCount: _images.length + 1,
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 10,
//                       mainAxisSpacing: 10,
//                     ),
//                     itemBuilder: (context, index) {
//                       if (index == _images.length) {
//                         return GestureDetector(
//                           onTap: _pickImages,
//                           child: Container(
//                             color: Colors.grey[300],
//                             child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
//                           ),
//                         );
//                       } else {
//                         return Image.file(
//                           File(_images[index].path),
//                           fit: BoxFit.cover,
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
        
//               // Spare Required Checkbox
//               CheckboxListTile(
//                 title: const Text('Spare Required'),
//                 value: _spareRequired,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     _spareRequired = value ?? false;
//                   });
//                 },
//               ),
        
//               // Cash Required Checkbox
//               CheckboxListTile(
//                 title: const Text('Cash Required'),
//                 value: _cashRequired,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     _cashRequired = value ?? false;
//                   });
//                 },
//               ),
        
//               // Submit Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _submitForm,
//                   child: const Text('Submit'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

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
  List<Map<String, dynamic>> _sites = [];
  List<dynamic> _supervisors = [];
  String? _selectedSite;
  bool _spareRequired = false;
  bool _cashRequired = false;
  List<XFile> _images = [];
  int? _tglAssigneeId;
  int? _rmAssigneeId;
  DateTime currentDateTime = DateTime.now();


  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchAssignedSites();
    fetchAllSupervisors();
  }

  Future<void> fetchAllSupervisors() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {'Authorization': basicAuth};

    try {
      var response = await http.get(
        Uri.parse('http://13.49.230.203:8080/api/user/supervisors'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        setState(() {
          _supervisors = data;
          _tglAssigneeId = _supervisors.firstWhere(
            (supervisor) => supervisor['role'] == 'TGL',
            orElse: () => null,
          )['id'];
          _rmAssigneeId = _supervisors.firstWhere(
            (supervisor) => supervisor['role'] == 'RM',
            orElse: () => null,
          )['id'];
        });
      } else {
        print('Error fetching supervisors: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchAssignedSites() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {'Authorization': basicAuth};

    var request = http.Request('GET', Uri.parse('http://13.49.230.203:8080/api/user/sites'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        List<dynamic> sites = json.decode(responseBody);
        setState(() {
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

  Future<void> _pickImages() async {
    if (_images.length >= 4) {
      print('Cannot select more than 4 images');
      return;
    }

    final pickedImage = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (pickedImage != null) {
      setState(() {
        _images.add(XFile(pickedImage.path));
      });
    } else {
      print('No image selected');
    }
  }

  Future<void> _submitForm() async {
    if (_tglAssigneeId == null || _rmAssigneeId == null) {
      print('No TGL or RM assigned');
      return;
    }

    String faultDescription = faultDescriptionController.text.isNotEmpty
        ? faultDescriptionController.text
        : "No description provided";
    String status = "PENDING";
    String type = _cashRequired ? "CASH" : "SPARE";
    int userId = widget.id;

    int? siteId = _selectedSite != null
        ? _sites.firstWhere((site) => site['siteName'] == _selectedSite)['siteId']
        : null;

    if (siteId == null) {
      print('No site selected');
      return;
    }

    var uri = Uri.parse('http://13.49.230.203:8080/api/request');

    var request = http.MultipartRequest('POST', uri);

    var requestJson = jsonEncode({
      'faultDescription': faultDescription,
      'status': status,
      'type': type,
      'currentLevel': 'TGL',
      'userId': userId,
      'siteId': siteId,
      'forwardTo': _tglAssigneeId,
      'forwardedBy': userId,
      'nextAssignee': _rmAssigneeId,
      'submissionDate': currentDateTime.toIso8601String(),
    });

    request.files.add(http.MultipartFile.fromString(
      'request',
      requestJson,
      contentType: MediaType('application', 'json'),
    ));

    for (var image in _images) {
      var stream = http.ByteStream(image.openRead());
      var length = await image.length();

      request.files.add(http.MultipartFile(
        'images',
        stream,
        length,
        filename: basename(image.path),
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
    request.headers['Authorization'] = basicAuth;

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        print('Uploaded successfully!');
        _resetForm();
      } else {
        print('Failed to upload. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _resetForm() {
    setState(() {
      faultDescriptionController.clear();
      _selectedSite = null;
      _spareRequired = false;
      _cashRequired = false;
      _images.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Site ID',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSite != null && _sites.any((site) => site['siteName'] == _selectedSite)
                    ? _selectedSite
                    : null,
                items: _sites.map((site) => DropdownMenuItem<String>(
                      value: site['siteName'],
                      child: Text(site['siteName']),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSite = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: faultDescriptionController,
                decoration: const InputDecoration(labelText: 'Fault Nature', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: GridView.builder(
                    itemCount: _images.length + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                    itemBuilder: (context, index) {
                      if (index == _images.length) {
                        return const Icon(Icons.camera_alt, size: 50);
                      }
                      return Image.file(File(_images[index].path));
                    },
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('Spare Required'),
                value: _spareRequired,
                onChanged: (value) => setState(() => _spareRequired = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Cash Required'),
                value: _cashRequired,
                onChanged: (value) => setState(() => _cashRequired = value ?? false),
              ),
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
      ),
    );
  }
}
