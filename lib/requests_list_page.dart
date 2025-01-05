import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'spares_details_page.dart';

class RequestsListPage extends StatefulWidget {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final String password;

  const RequestsListPage({
    Key? key,
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.password,
  }) : super(key: key);

  @override
  State<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends State<RequestsListPage> {
  List<dynamic> _requests = [];
  Map<int, String> _siteIdToNameMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSiteDetails().then((_) => _fetchApprovedRequests());
  }

  Future<void> _fetchSiteDetails() async {
    const String siteUrl = "http://13.49.230.203:8080/api/user/sites";
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth};

      var response = await http.get(Uri.parse(siteUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> sites = json.decode(response.body);
        setState(() {
          for (var site in sites) {
            _siteIdToNameMap[site['siteId']] = site['siteName'];
          }
        });
      } else {
        print("Error fetching site details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching site details: $e");
    }
  }

  Future<void> _fetchApprovedRequests() async {
    const String apiUrl = "http://13.49.230.203:8080/api/request/co/requests";
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth};

      var response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> requests = json.decode(response.body);
        setState(() {
          _requests = requests
              .where((req) => req['status'] == 'APPROVED')
              .toList();
          _requests.sort((a, b) => b['id'].compareTo(a['id']));
          _isLoading = false;
        });
      } else {
        print("Error fetching approved requests: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching approved requests: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getSiteName(int? siteId) {
    if (siteId == null) return 'N/A';
    return _siteIdToNameMap[siteId] ?? 'Unknown Site';
  }

  void _navigateToSparesPage(Map<String, dynamic> request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SparesDetailsPage(
          id: widget.id,
          requestId: request['id'], // Pass the request ID here
          username: widget.username,
          fullName: widget.fullName,
          role: widget.role,
          password: widget.password,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approved Requests")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text("No approved requests available"))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text("Request ID: ${request['id']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Site: ${getSiteName(request['siteId'])}"),
                            Text("Status: ${request['status']}"),
                            Text(
                                "Fault Description: ${request['faultDescription'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.blue),
                          onPressed: () => _navigateToSparesPage(request),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
