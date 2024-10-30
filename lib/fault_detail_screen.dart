import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FaultDetailScreen extends StatefulWidget {
  final int officerId;
  final String officerName;
  final int requestId; // To pass the request ID for details
  final String username;
  final String password;

  const FaultDetailScreen({
    Key? key,
    required this.officerId,
    required this.officerName,
    required this.requestId,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<FaultDetailScreen> createState() => _FaultDetailScreenState();
}

class _FaultDetailScreenState extends State<FaultDetailScreen> {
  Map<String, dynamic>? _requestDetails; // Store the request details
  Map<int, String> _siteIdToNameMap = {}; // Map to store site IDs and names
  bool _isLoading = true;
  // ignore: unused_field
  bool _isProcessing = false;

  // Define your backend IP address here
  final String serverIp = 'http://13.49.230.203:8080';

  @override
  void initState() {
    
    super.initState();
    fetchRequestDetails();
    fetchSiteDetails(); // Fetch site details on initialization
  }

  // Fetch site details to map site IDs to names
  Future<void> fetchSiteDetails() async {
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {
        'Authorization': basicAuth,
      };

      var request = http.Request(
        'GET',
        Uri.parse('$serverIp/api/user/sites'),
      );
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        List<dynamic> sites = jsonDecode(responseBody);

        // Store site IDs and names in the map
        setState(() {
          for (var site in sites) {
            _siteIdToNameMap[site['siteId']] = site['siteName'];
          }
        });
      } else {
        print('Error fetching site details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch the details of the specific request using the request ID
  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {
        'Authorization': basicAuth,
      };

      var request = http.Request(
        'GET',
        Uri.parse('$serverIp/api/request/requests'),
      );
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        List<dynamic> requests = jsonDecode(responseBody);

        var matchedRequest = requests.firstWhere(
          (request) => request['id'] == widget.requestId,
          orElse: () => null,
        );

        if (matchedRequest != null) {
          setState(() {
            _requestDetails = matchedRequest;
            _isLoading = false;
          });
        } else {
          print('Request with ID ${widget.requestId} not found');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to replace 'localhost' with the server IP in image URLs
  String replaceLocalhostWithIP(String imagePath) {
    return imagePath.replaceAll('http://localhost:8080', serverIp);
  }

  // Function to get the site name from the site ID
  String getSiteName(int? siteId) {
    if (siteId == null) return 'N/A';
    return _siteIdToNameMap[siteId] ?? 'Unknown Site';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  // Display Site Name instead of Site ID
                  Text(
                    'Site: ${getSiteName(_requestDetails?['siteId'])}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),

                  // Officer ID and Name
                  Text(
                    'Officer: ${widget.officerName} (ID: ${widget.officerId})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Fault Description
                  Text(
                    'Fault Description: ${_requestDetails?['faultDescription'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Request Type
                  Text(
                    'Request Type: ${_requestDetails?['type'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Status
                  Text(
                    'Status: ${_requestDetails?['status'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Date of Submission
                  Text(
                    'Submission Date: ${_requestDetails?['submissionDate'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Evidence Images Section
                  const Text(
                    'Evidence',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Display Evidence Images
                  _requestDetails?['imagePaths'] != null &&
                          _requestDetails!['imagePaths'].isNotEmpty
                      ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1,
                        ),
                        itemCount: _requestDetails!['imagePaths'].length,
                        itemBuilder: (context, index){
                          String imagePath =
                          _requestDetails!['imagePaths'][index]['imagePath'];
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(index),
                            child: buildImageWidget(imagePath),
                          );
                        },
                      )
                      : const Text('No evidence provided'),

                  const SizedBox(height: 20),

                  // Action Buttons (Verify, Reject)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _verifyRequest,
                        child: const Text('Verify'),
                      ),
                      ElevatedButton(
                        onPressed: _rejectRequest, // Reject request button
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Function to verify the request
  Future<void> _verifyRequest() async {
    setState(() {
      _isProcessing = true; //Start Processing
    });
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      };

      var request = http.Request(
        'PUT',
        Uri.parse('$serverIp/api/request/${widget.requestId}'),
      );

      // Prepare the request body for the verification process
      request.body = json.encode({
        "status": "VERIFIED", // Set status to VERIFIED
        "currentLevel": "RM", // Forward to RM
        "userId": _requestDetails?['userId'], // User who submitted the request
        "siteId": _requestDetails?['siteId'], // Site ID
        "forwardTo": 2, // ID of the RM (change as needed)
        "verifiedBy": widget.officerId, // ID of the officer verifying the request
        "forwardedBy": widget.officerId, // Forwarding officer ID
        "approvedBy": null, // Approved by remains null at this stage
        "nextAssignee": 1, // ID of the PM (change as needed) 
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print('Request verified successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request verified successfully')),
        );
        Navigator.pop(context);
      } else {
        print('Error verifying request: ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying request: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally{
      setState(() {
        _isProcessing = false;
      });
    }
  }

   // Function to reject the request
Future<void> _rejectRequest() async {
  setState(() {
    _isProcessing = true;
  });

  try {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    var requestBody = json.encode({
      "status": "DECLINED", // Set status to REJECTED
      "currentLevel": "TGL", // Reset current level to CO (or other level based on your flow)
      "userId": _requestDetails?['userId'], // User who submitted the request
      "siteId": _requestDetails?['siteId'], // Site ID
      "forwardedBy": widget.officerId, // Officer rejecting the request
      "forwardTo": _requestDetails?['userId'], // Ensure forwardTo is null
      "verifiedBy": null, // Ensure verifiedBy is null
      "approvedBy": null, // Ensure approvedBy is null
      "nextAssignee": null // Ensure nextAssignee is null
    });

    var response = await http.put(
      Uri.parse('$serverIp/api/request/${widget.requestId}'),
      headers: headers,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      print('Request rejected successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected successfully')),
      );
      Navigator.pop(context);
    } else {
      print('Error rejecting request: ${response.statusCode} - ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally{
    _isProcessing = false;
  }
}


  // Build the evidence image widget with authentication headers
  Widget buildImageWidget(String imagePath) {
    String imageUrl = replaceLocalhostWithIP(imagePath);
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
    

    return Image.network(
      imageUrl,
      height: 200,
      fit: BoxFit.cover,
      headers: {'Authorization': basicAuth, "Cache-Control": "no-cache"}, // Authorization header for image
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return Container(
          height: 200,
          color: Colors.grey,
          child: const Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
  void _showFullScreenImage(int index){
  showDialog(context: context, builder: (context){
    return Dialog(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: PhotoViewGallery.builder(
          itemCount: _requestDetails!['imagePaths'].length,
          builder: (context, index) {
            String imagePath =
            replaceLocalhostWithIP(_requestDetails!['imagePaths'][index]['imagePath']);
            String basicAuth = 'Basic ' +
            base64Encode(utf8.encode('${widget.username}:${widget.password}'));

            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(
                imagePath,
                headers: {'Authorization': basicAuth},
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,

            );
          },
          pageController: PageController(initialPage: index),
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          )
        ),
      ),
    );
  });
}

}

