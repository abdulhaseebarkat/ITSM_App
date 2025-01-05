import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


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
    _requestPermissions();
    fetchAssignedSites();
    fetchAllSupervisors();
  }

Future<void> _requestPermissions() async {
  // Check for location, camera, and storage permissions one by one
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }

  if (await Permission.camera.isDenied) {
    await Permission.camera.request();
  }

  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  // Handle the case where permissions are permanently denied
  if (await Permission.location.isPermanentlyDenied || 
      await Permission.camera.isPermanentlyDenied || 
      await Permission.storage.isPermanentlyDenied) {
    await openAppSettings();
  }
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

Future<void> _pickImages(BuildContext context) async {
  if (_images.length >= 4) {
    print('Cannot select more than 4 images');
    return;
  }
  try {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose the Image Source: Camera or Gallery'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null) {
      print('No Source Selected');
      return;
    }

    final pickedImage = await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image != null) {
        if (source == ImageSource.camera) {
          // Add location watermark for camera images
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          double latitude = position.latitude;
          double longitude = position.longitude;
          DateTime currentDate = DateTime.now();

          List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
          Placemark place = placemarks[0];
          String locationName = "${place.subLocality}, ${place.locality}, ${place.country}";

          _addLocationWatermark(image, locationName, latitude, longitude, currentDate);
          print('Image selected and geotagged with location: $locationName');
        } else {
          // Add "Uploaded from gallery" watermark for gallery images
          _addGalleryWatermark(image);
          print("Image selected from gallery with gallery watermark");
        }

        // Save the updated image with watermark
        final directory = await getTemporaryDirectory();
        String newPath = "${directory.path}/watermarked_${basename(pickedImage.path)}";
        File(newPath).writeAsBytesSync(img.encodeJpg(image, quality: 80));

        setState(() {
          _images.add(XFile(newPath));
        });
      }
    } else {
      print('No Image selected');
    }
  } catch (e) {
    print('Error picking the image: $e');
  }
}

// Function to add location watermark
void _addLocationWatermark(img.Image image, String locationName, double latitude, double longitude, DateTime date) {
  final font = img.arial_48;
  String watermarkText = 'Location: $locationName\nLatitude: $latitude, Longitude: $longitude\nDate: ${date.toLocal().toString().split(' ')[0]}';
  
  int xPos = 20;
  int yPos = image.height - 100;

  img.fillRect(image, xPos - 10, yPos - 70, xPos + 1200, yPos + 80, img.getColor(0, 0, 0));
  img.drawString(image, font, xPos + 25, yPos - 60, watermarkText, color: img.Color.fromRgb(255, 255, 255));
}

// Function to add "Uploaded from gallery" watermark
void _addGalleryWatermark(img.Image image) {
  final font = img.arial_48;
  String watermarkText = 'Uploaded from gallery';

  int xPos = 20;
  int yPos = image.height - 50;

  img.fillRect(image, xPos - 10, yPos - 50, xPos + 600, yPos + 40, img.getColor(0, 0, 0));
  img.drawString(image, font, xPos + 25, yPos - 40, watermarkText, color: img.Color.fromRgb(255, 255, 255));
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
                onTap: () => _pickImages(context),
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
                onChanged: (value) {
                  setState(() {
                    _spareRequired = value ?? false;
                    _cashRequired = false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Cash Required'),
                value: _cashRequired,
                onChanged: (value){
                  setState(() {
                    _cashRequired = value ?? false;
                    _spareRequired = false;
                  });
                },
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
