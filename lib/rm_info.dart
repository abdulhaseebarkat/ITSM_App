import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequestDetails(); // Fetch request details when the screen loads
  }

  // Fetch request details by ID
  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {
        'Authorization': basicAuth,
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

  // Function to handle the update request (for approve/forward/reject actions)
  Future<void> updateRequest(String status, String currentLevel, int? forwardTo, int? approvedBy) async {
    var requestBody = jsonEncode({
      "status": status,
      "currentLevel": currentLevel,
      "userId": _requestDetails?['userId'], // User who submitted the request
      "siteId": _requestDetails?['siteId'], // Site associated with the request
      "forwardTo": forwardTo, // PM's ID or null
      "verifiedBy": _requestDetails?['verifiedBy'], // RM's ID for verification
      "forwardedBy": widget.officerId, // RM's ID for forwarding
      "approvedBy": approvedBy, // RM's ID when approving
      "nextAssignee": forwardTo == 1 ? 1 : null, // PM's ID when forwarding to PM
    });

    print('Request body: $requestBody'); // Log the request body for debugging

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      var response = await http.put(
        Uri.parse('http://192.168.32.157:8080/api/request/${widget.requestId}'),
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
                  Text(
                    'Site: ${_requestDetails?['siteId'] ?? 'N/A'}',
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
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Failed to load image'),
                              ),
                            );
                          },
                        )
                      : const Text('No evidence provided'),
                  const SizedBox(height: 20),
                  // Action Buttons (Approve, Forward to PM, Reject)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Approve button logic (status = "APPROVED", currentLevel = "PM")
                          updateRequest("APPROVED", "PM", null, widget.officerId);
                        },
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Forward to PM button logic (status = "VERIFIED", currentLevel = "PM", forwardTo = 1 (PM))
                          updateRequest("VERIFIED", "PM", 1, null); // PM's ID = 1
                        },
                        child: const Text('Forward to PM'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Reject button logic (status = "REJECTED", currentLevel = "CO")
                          updateRequest("REJECTED", "CO", null, null);
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
