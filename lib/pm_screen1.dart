import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telecom_app/pm_info.dart';

class PMList extends StatefulWidget {
  final int id; // PM's ID
  final String username;
  final String fullName;
  final String role;
  final String password;

  PMList({
    super.key,
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.password,
  });

  @override
  _PMListState createState() => _PMListState();
}

class _PMListState extends State<PMList> {
  List<Map<String, dynamic>> _requests = []; // To store filtered requests
  Map<int, String> _rmNames = {}; // To store RM names mapped by siteId

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // Fetch requests forwarded to the PM
  Future<void> fetchRequests() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    var request = http.Request('GET', Uri.parse('http://192.168.32.157:8080/api/request/requests'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Requests fetched: $responseBody');

        // Decode and filter the requests for the PM (forwardTo should match PM ID)
        List<dynamic> requests = json.decode(responseBody);
        setState(() {
          _requests = List<Map<String, dynamic>>.from(
            requests.where((request) => request['forwardTo'] == widget.id),
          );
        });

        // Fetch RM names based on siteId in the requests
        for (var request in _requests) {
          int siteId = request['siteId'];
          int verifiedById = request['verifiedBy']; // Use verifiedBy field for RM
          fetchRMName(siteId, verifiedById);
        }
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch the RM's name using the siteId and verifiedById from the request
  Future<void> fetchRMName(int siteId, int userId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    print('Fetching users for siteId: $siteId'); // Debugging

    var response = await http.get(
      Uri.parse('http://192.168.32.157:8080/api/site/$siteId/users'), // Fetch users by siteId
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body);
      print('Users fetched for siteId $siteId: $users'); // Debugging users list

      // Find the RM by matching the userId and role
      bool foundRM = false;
      for (var user in users) {
        if (user['id'] == 2 && user['role'] == 'RM') {
          setState(() {
            _rmNames[userId] = user['fullName']; // Store the RM's name by userId
          });
          print('RM found: ${user['fullName']}'); // Debugging found RM
          foundRM = true;
          break;
        }
      }
      if (!foundRM) {
        print('RM not found for siteId $siteId and userId $userId'); // Debugging when RM not found
      }
    } else {
      print('Error fetching RM name: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forwarded Requests', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _requests.isEmpty
          ? const Center(child: Text("No requests found"))
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                final rmName = _rmNames[request['verifiedBy']] ?? 'Loading RM...';

                return ListTile(
                  title: Text('RM: $rmName'), // Display RM's name
                  subtitle: Text('Request ID: ${request['id']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PMInfo(
                            officerId: widget.id, // Pass PM's ID
                            officerName: rmName, // Pass RM's name
                            username: widget.username,
                            password: widget.password,
                            requestId: request['id'],
                          ),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                );
              },
            ),
    );
  }
}
