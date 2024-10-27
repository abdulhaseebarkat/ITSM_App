import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
class PMInfo extends StatefulWidget {
  final int officerId;
  final String officerName;
  final int requestId; // To pass the request ID for details
  final String username;
  final String password;

  const PMInfo({
    Key? key,
    required this.officerId,
    required this.officerName,
    required this.requestId,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<PMInfo> createState() => _PMInfoState();
}

class _PMInfoState extends State<PMInfo> {
  Map<String, dynamic>? _requestDetails;
  bool _isLoading = true;
  //ignore: unused_field
  bool _isProcessing = false;
  Map<int, String> _siteIdToNameMap = {}; // Map to store site IDs and names


  // Define your backend IP address here
  final String serverIp = 'http://13.49.230.203:8080';

  @override
  void initState() {
    super.initState();
    fetchRequestDetails(); // Fetch request details when the screen loads
    fetchSiteDetails();
  }

  // Function to replace 'localhost' with the server IP in image URLs
  String replaceLocalhostWithIP(String imagePath) {
    return imagePath.replaceAll('http://localhost:8080', serverIp);
  }

    // Function to fetch the site details
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

    // Function to get the site name from the site ID
  String getSiteName(int? siteId) {
    if (siteId == null) return 'N/A';
    return _siteIdToNameMap[siteId] ?? 'Unknown Site';
  }

  // Fetch request details by ID
  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
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

  // Function to handle the update request (approve/reject actions)
  Future<void> updateRequest(String status) async {
    setState(() {
      _isProcessing = true;
    });
    var requestBody = jsonEncode({
      "status": status,
      "currentLevel": "PM", // Update the current level to PM
      "userId": _requestDetails?['userId'], // User who submitted the request
      "siteId": _requestDetails?['siteId'], // Site associated with the request
      "forwardTo": null, // No forwardTo for approval
      "verifiedBy": _requestDetails?['verifiedBy'], // RM's ID for verification
      "forwardedBy": _requestDetails?['forwardedBy'], // RM's ID for forwarding
      "approvedBy": widget.officerId, // PM's ID when approving
      "nextAssignee": null, // No next assignee after approval
    });

    print('Request body: $requestBody'); // Log the request body for debugging

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      var response = await http.put(
        Uri.parse('$serverIp/api/request/${widget.requestId}'),
        headers: headers,
        body: requestBody,
      );

      // Log the full response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Request updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated successfully')),
        );
        Navigator.pop(context);
      } else {
        print('Error updating request: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    finally{
      setState(() {
        _isProcessing = false;
      });
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
                  Text(
                    'Site: ${getSiteName(_requestDetails?['siteId'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fault Description: ${_requestDetails?['faultDescription'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Request Type: ${_requestDetails?['type'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${_requestDetails?['status'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submission Date: ${_requestDetails?['submissionDate'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Evidence',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _requestDetails?['imagePaths'] != null &&
                          _requestDetails!['imagePaths'].isNotEmpty
                      ? GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1,
                        ),
                        itemCount: _requestDetails?['imagePaths'].length,
                        itemBuilder: (context, index) {
                          String imagePath =
                          _requestDetails?['imagePaths'][index]['imagePath'];
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(index),
                            child: buildImageWidget(imagePath),
                          );
                        },
                      )
                      : const Text('No evidence provided'),
                  const SizedBox(height: 20),
                  // Action Buttons (Approve, Reject)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Approve button logic (status = "APPROVED")
                          updateRequest("APPROVED");
                        },
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Reject button logic (status = "REJECTED")
                          updateRequest("DECLINED");
                        },
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  void _showFullScreenImage(int index){
    showDialog(context: context, builder: (context){
      return Dialog(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: PhotoViewGallery.builder(itemCount: _requestDetails?['imagePaths'].length,
           builder: (context, index) {
            String imagePath =
            replaceLocalhostWithIP(_requestDetails?['imagePaths'][index]['imagePath']);
            String basicAuth = 'Basic' +
            base64Encode(utf8.encode('${widget.username}:${widget.password}'));

            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imagePath,
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
           ),
           ),
        ),
      );
    });
  }
}
