import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telecom_app/rm_info.dart';

class RMList extends StatefulWidget {
  final int id; // RM's ID
  final String username;
  final String fullName;
  final String role;
  final String password;

  RMList({
    super.key,
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.password,
  });

  @override
  _RMListState createState() => _RMListState();
}

class _RMListState extends State<RMList> {
  List<Map<String, dynamic>> _requests = []; // To store filtered requests
  Map<int, String> _tglNames = {}; // To store TGL names mapped by userId

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // Fetch requests forwarded to the RM
  Future<void> fetchRequests() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    var request = http.Request('GET', Uri.parse('http://192.168.89.106:8080/api/request/requests'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Requests fetched: $responseBody'); // Debugging response

        // Decode and filter the requests for the RM (forwardTo should match RM ID)
        List<dynamic> requests = json.decode(responseBody);
        setState(() {
          _requests = List<Map<String, dynamic>>.from(
            requests.where((request) => request['forwardTo'] == widget.id),
          );
        });

        // Fetch TGL names based on siteId in the requests
        for (var request in _requests) {
          int siteId = request['siteId'];
          int verifiedById = request['verifiedBy']; // Use verifiedBy field
          fetchTGLName(siteId, verifiedById);
        }
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch the TGL's name using the siteId and verifiedById from the request
  Future<void> fetchTGLName(int siteId, int userId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    print('Fetching users for siteId: $siteId'); // Debugging

    var response = await http.get(
      Uri.parse('http://192.168.89.106:8080/api/site/$siteId/users'), // Fetch users by siteId
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body);
      print('Users fetched for siteId $siteId: $users'); // Debugging users list

      // Find the TGL by matching the userId and role
      bool foundTGL = false;
      for (var user in users) {
        if (user['id'] == userId && user['role'] == 'TGL') {
          setState(() {
            _tglNames[userId] = user['fullName']; // Store the TGL's name by userId
          });
          print('TGL found: ${user['fullName']}'); // Debugging found TGL
          foundTGL = true;
          break;
        }
      }
      if (!foundTGL) {
        print('TGL not found for siteId $siteId and userId $userId'); // Debugging when TGL not found
      }
    } else {
      print('Error fetching TGL name: ${response.reasonPhrase}');
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
                final tglName = _tglNames[request['verifiedBy']] ?? 'Loading TGL...';

                return ListTile(
                  title: Text('TGL: $tglName'), // Display TGL's name
                  subtitle: Text('Request ID: ${request['id']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RMInfo(
                            officerId: widget.id, // Pass TGL's ID
                            officerName: tglName, // Pass TGL's name
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
