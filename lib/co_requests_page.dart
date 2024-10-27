import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:telecom_app/request_detail_page.dart';

class CORequestsPage extends StatefulWidget {
  final int id;
  final String username;
  final String password;
  
  const CORequestsPage({
    Key? key,
    required this.id,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  _CORequestsPageState createState() => _CORequestsPageState();
}

class _CORequestsPageState extends State<CORequestsPage> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  Map<int, String> _siteIdToNameMap = {}; // Map to store site IDs and names
  final String serverIp = 'http://13.49.230.203:8080';


  @override
  void initState() {
    super.initState();
    fetchCORequests();
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

  Future<void> fetchCORequests() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth};

      var response = await http.get(
        Uri.parse('http://13.49.230.203:8080/api/request/co/requests'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _requests = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print('Error fetching requests: ${response.statusCode}');
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

    String getSiteName(int? siteId) {
    if (siteId == null) return 'N/A';
    return _siteIdToNameMap[siteId] ?? 'Unknown Site';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                var request = _requests[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('Request ID: ${request['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                    'Site: ${getSiteName(request?['siteId'])}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                        Text('Status: ${request['status']}'),
                        Text('Current Level: ${request['currentLevel']}'),
                        Text('Fault Description: ${request['faultDescription'] ?? 'N/A'}'),
                        Text('Type: ${request['type'] ?? 'N/A'}'),
                        Text('Submission Date: ${request['submissionDate'] ?? 'N/A'}'),
                      ],
                    ),
                    onTap: () {
                      // Navigate to the detail page with the request data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestDetailPage(
                            request: request,
                            username: widget.username,
                            password: widget.password,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
