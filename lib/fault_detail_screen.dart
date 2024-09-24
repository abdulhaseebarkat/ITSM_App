import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    required this.password
  }) : super(key: key);

  @override
  State<FaultDetailScreen> createState() => _FaultDetailScreen();
}

class _FaultDetailScreen extends State<FaultDetailScreen> {
  Map<String, dynamic>? _requestDetails; // Store the request details
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('Passed requestId: ${widget.requestId}');
    fetchRequestDetails();
  }

  // Fetch the details of the specific request using the request ID
  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {
        'Authorization': basicAuth,
        'Cookie': 'JSESSIONID=8FB4F9FE4085C167E4D983AC8EC62968',
      };

      var request = http.Request(
        'GET',
        Uri.parse('http://192.168.32.157:8080/api/request/requests'),
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

  // Function to verify the request
  Future<void> _verifyRequest() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      };

      var request = http.Request(
        'PUT',
        Uri.parse('http://192.168.32.157:8080/api/request/${widget.requestId}'), // Update request ID here
      );

      // Prepare the request body as per the flow
      request.body = json.encode({
        "status": "VERIFIED", // Set status to VERIFIED
        "currentLevel": "RM", // Forward to RM
        "userId": _requestDetails?['userId'], // User who submitted the request
        "siteId": _requestDetails?['siteId'],
        "forwardTo": 2, // ID of the RM
        "verifiedBy": widget.officerId, // ID of the TGL verifying the request
        "forwardedBy": widget.officerId, // ID of the TGL who forwards
        "approvedBy": null, // Approved by is null at this stage
        "nextAssignee": 1 // ID of the PM
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print('Request verified successfully');
        // Handle successful verification (you can show a message or navigate to another page)
      } else {
        print('Error verifying request: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Site ID (or Name)
                  Text(
                    'Site: ${_requestDetails?['siteId'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

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

                  // Evidence Images Section
            const Text(
              'Evidence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _requestDetails?['imagePath'] != null
                ? Image.network(
                    _requestDetails!['imagePath'],
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
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
                        onPressed: () {
                          // Reject button logic here
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
}
