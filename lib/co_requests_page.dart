import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  DateTime curDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchCORequests();
  }

  // Fetch CO's requests
  Future<void> fetchCORequests() async {
    try {
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {
        'Authorization': basicAuth,
      };

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
                        Text('Status: ${request['status']}'),
                        Text('Current Level: ${request['currentLevel']}'),
                        Text('Fault Description: ${request['faultDescription'] ?? 'N/A'}'),
                        Text('Type: ${request['type'] ?? 'N/A'}'),
                        Text('Submission Date: ${request['submissionDate'] ?? 'N/A'}'),
                        Text('View Date: ${curDateTime}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
