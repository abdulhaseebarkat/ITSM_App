import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telecom_app/fault_detail_screen.dart';

class COList extends StatefulWidget {
  final int id; // TGL's ID
  final String username;
  final String fullName;
  final String role;
  final String password;

  COList(
      {super.key,
      required this.id,
      required this.username,
      required this.fullName,
      required this.role,
      required this.password});

  @override
  _COListState createState() => _COListState();
}

class _COListState extends State<COList> {
  List<Map<String, dynamic>> _requests = []; // To store filtered requests
  Map<int, String> _coNames = {}; // To store CO names mapped by their userId

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    var request =
        http.Request('GET', Uri.parse('http://192.168.32.157:8080/api/request/requests'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Requests fetched: $responseBody');

        // Decode and filter the requests for the TGL (forwardTo should match TGL ID)
        List<dynamic> requests = json.decode(responseBody);
        setState(() {
          _requests = List<Map<String, dynamic>>.from(
            requests.where((request) => request['forwardTo'] == widget.id),
          );
        });

        // Fetch CO names based on userId in the requests
        for (var request in _requests) {
          int siteId = request['siteId'];
          fetchCOName(siteId, request['userId']);
        }
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchCOName(int siteId, int userId) async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    var headers = {
      'Authorization': basicAuth,
    };

    var response = await http.get(
      Uri.parse('http://192.168.32.157:8080/api/site/$siteId/users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body);

      // Find the CO from the list of users
      for (var user in users) {
        if (user['id'] == userId && user['role'] == 'CO') {
          setState(() {
            _coNames[userId] = user['fullName']; // Store the CO's name
          });
          break;
        }
      }
    } else {
      print('Error fetching CO name: ${response.reasonPhrase}');
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
                final coName = _coNames[request['userId']] ?? 'Loading CO...';

                return ListTile(
                  title: Text('CO: $coName'), // Display CO's name
                  subtitle: Text('Request ID: ${request['id']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FaultDetailScreen(
                            officerId: widget.id, // Pass userId (CO's ID)
                            officerName: coName, requestId: request['id'], // Pass CO's name
                            username: widget.username,
                            password: widget.password,
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

