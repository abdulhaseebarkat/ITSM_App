import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class RequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> request;
  final String username;
  final String password;

  const RequestDetailPage({
    Key? key,
    required this.request,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  _RequestDetailPageState createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  late Future<List<dynamic>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = fetchRequestImages();
    
  }

  Future<List<dynamic>> fetchRequestImages() async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
    var headers = {'Authorization': basicAuth};

    var response = await http.get(
      Uri.parse('http://13.49.230.203:8080/api/request/${widget.request['id']}/images'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details: ${widget.request['id']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fault Description: ${widget.request['faultDescription'] ?? 'N/A'}'),
            Text('Status: ${widget.request['status']}'),
            Text('Current Level: ${widget.request['currentLevel']}'),
            Text('Type: ${widget.request['type']}'),
            Text('Submission Date: ${widget.request['submissionDate']}'),
            const SizedBox(height: 16),
            const Text('Images:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            FutureBuilder<List<dynamic>>(
              future: _imagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No images available.');
                } else {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var imageUrl = snapshot.data![index]['url'];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(imageUrl),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
