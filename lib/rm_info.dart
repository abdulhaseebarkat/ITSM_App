import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class RMInfo extends StatefulWidget {
  final int officerId;
  final String officerName;
  final int requestId; // To pass the request ID for details
  final String username;
  final String password;

  const RMInfo({
    Key? key,
    required this.officerId,
    required this.officerName,
    required this.requestId,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<RMInfo> createState() => _RMInfoState();
}

class _RMInfoState extends State<RMInfo> {
  Map<String, dynamic>? _requestDetails;
  Map<int, String> _siteIdToNameMap = {}; // Map to store site IDs and names
  bool _isLoading = true;
  //ignore: unused_field
  bool _isProcessing = false;

  // Define your backend IP address here
  final String serverIp = 'http://13.49.230.203:8080';

  @override
  void initState() {
    super.initState();
    fetchRequestDetails(); // Fetch request details when the screen loads
    fetchSiteDetails(); // Fetch site details to map site IDs to names
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

  // Function to fetch request details
  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
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

  // Function to update the request (as in the original code)
  Future<void> updateRequest(String status, String currentLevel, int? forwardTo, int? approvedBy) async {
    setState(() {
      _isProcessing = true;
    });
    var requestBody = jsonEncode({
      "status": status,
      "currentLevel": currentLevel,
      "userId": _requestDetails?['userId'],
      "siteId": _requestDetails?['siteId'],
      "forwardTo": forwardTo,
      "verifiedBy": _requestDetails?['verifiedBy'],
      "forwardedBy": widget.officerId,
      "approvedBy": approvedBy,
      "nextAssignee": forwardTo == 1 ? 1 : null,
    });

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

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: ${response.statusCode}')),
        );
      }
    } catch (e) {
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

  // Widget to build images
  Widget buildImageWidget(String imagePath) {
    String imageUrl = replaceLocalhostWithIP(imagePath);
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    return Image.network(
      imageUrl,
      height: 200,
      fit: BoxFit.cover,
      headers: {'Authorization': basicAuth, "Cache-Control": "no-cache"},
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey,
          child: const Center(child: Text('Failed to load image')),
        );
      },
    );
  }

  // Replace localhost with IP
  String replaceLocalhostWithIP(String imagePath) {
    return imagePath.replaceAll('http://localhost:8080', serverIp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  // Display Site Name instead of Site ID
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
                  const Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _requestDetails?['imagePaths'] != null && _requestDetails!['imagePaths'].isNotEmpty
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          updateRequest("APPROVED", "PM", null, widget.officerId);
                        },
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateRequest("VERIFIED", "PM", 1, null); // PM's ID = 1
                        },
                        child: const Text('Forward to PM'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateRequest("DECLINED", "CO", null, null);
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
