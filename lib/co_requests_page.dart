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
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  Map<int, String> _siteIdToNameMap = {};
  final String serverIp = 'http://13.49.230.203:8080';

  // Status filtering variables
  final List<String> _statuses = ['PENDING', 'APPROVED', 'DECLINED', 'VERIFIED'];
  int _selectedStatusIndex = -1; // No status selected initially

  @override
  void initState() {
    super.initState();
    fetchCORequests();
    fetchSiteDetails();
  }

  Future<void> fetchSiteDetails() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth};

      var request = http.Request('GET', Uri.parse('$serverIp/api/user/sites'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        List<dynamic> sites = jsonDecode(responseBody);

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
          _filteredRequests = _requests;
          _isLoading = false;
          _requests.sort((a,b) => b['id'].compareTo(a['id']));
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

  void _filterRequests(int selectedIndex) {
    setState(() {
      _selectedStatusIndex = selectedIndex;

      // Filter the requests based on the selected status
      if (_selectedStatusIndex == -1) {
        _filteredRequests = _requests; // Show all requests if no status is selected
      } else {
        String selectedStatus = _statuses[_selectedStatusIndex];
        _filteredRequests = _requests
            .where((request) => request['status'] == selectedStatus)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ToggleButtons(
                    isSelected: List.generate(_statuses.length, (index) => index == _selectedStatusIndex),
                    onPressed: (int index) {
                      // Toggle the selected status or clear selection
                      _filterRequests(index == _selectedStatusIndex ? -1 : index);
                    },
                    children: _statuses.map((status) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(status),
                    )).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      var request = _filteredRequests[index];
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text('Status: ${request['status']}'),
                              Text('Current Level: ${request['currentLevel']}'),
                              Text('Fault Description: ${request['faultDescription'] ?? 'N/A'}'),
                              Text('Type: ${request['type'] ?? 'N/A'}'),
                              Text('Submission Date: ${request['submissionDate'] ?? 'N/A'}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CORequestDetailScreen(
                                  username: widget.username,
                                  password: widget.password,
                                  requestId: request?['id'] ?? 0,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
