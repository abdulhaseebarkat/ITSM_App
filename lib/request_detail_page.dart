// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class RequestDetailPage extends StatefulWidget {
//   final Map<String, dynamic> request;
//   final String username;
//   final String password;
//   final String siteName;

//   const RequestDetailPage({
//     Key? key,
//     required this.request,
//     required this.username,
//     required this.password,
//     required this.siteName,
//   }) : super(key: key);

//   @override
//   _RequestDetailPageState createState() => _RequestDetailPageState();
// }

// class _RequestDetailPageState extends State<RequestDetailPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Request Details: ${widget.request['id']}'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//               Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Site: ',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('${widget.siteName}'),
//               ),
//             ),
//             Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Fault Description',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(widget.request['faultDescription'] ?? 'N/A'),
//               ),
//             ),
//             Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Status',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(widget.request['status']),
//               ),
//             ),
//             Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Current Level',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(widget.request['currentLevel']),
//               ),
//             ),
//             Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Type',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(widget.request['type']),
//               ),
//             ),
//             Card(
//               elevation: 4,
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: const Text(
//                   'Submission Date',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('${widget.request['submissionDate'] ??'N/A'}'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CORequestDetailScreen extends StatefulWidget {
  final int requestId;
  final String username;
  final String password;

  const CORequestDetailScreen({
    Key? key,
    required this.requestId,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<CORequestDetailScreen> createState() => _CORequestDetailScreenState();
}

class _CORequestDetailScreenState extends State<CORequestDetailScreen> {
  Map<String, dynamic>? _requestDetails;
  bool _isLoading = true;
    Map<int, String> _siteIdToNameMap = {}; // Map to store site IDs and names


  final String serverIp = 'http://13.49.230.203:8080';

  @override
  void initState() {
    super.initState();
    fetchRequestDetails();
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

  Future<void> fetchRequestDetails() async {
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth};

      var request = http.Request('GET', Uri.parse('$serverIp/api/request/co/requests'));
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
        print('Error fetching request details: ${response.reasonPhrase}');
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

  String replaceLocalhostWithIP(String imagePath) {
    return imagePath.replaceAll('http://localhost:8080', serverIp);
  }

    // Function to get the site name from the site ID
  String getSiteName(int? siteId) {
    if (siteId == null) return 'N/A';
    return _siteIdToNameMap[siteId] ?? 'Unknown Site';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Request ID', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${widget.requestId}'),
                    ),
                  ),
                                    Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                  title: const Text(
                  'Site Name',
                 style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(getSiteName(_requestDetails?['siteId'])),
              ),
            ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Fault Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_requestDetails?['faultDescription'] ?? 'N/A'),
                    ),
                  ),

                  Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                  title: const Text(
                  'Current Level',
                 style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_requestDetails?['currentLevel'] ?? 'N/A'),
              ),
            ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Request Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_requestDetails?['type'] ?? 'N/A'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Evidence',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _requestDetails?['imagePaths'] != null &&
                          _requestDetails!['imagePaths'].isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1,
                          ),
                          itemCount: _requestDetails!['imagePaths'].length,
                          itemBuilder: (context, index) {
                            String imagePath =
                                _requestDetails!['imagePaths'][index]['imagePath'];
                            return GestureDetector(
                              onTap: () => _showFullScreenImage(index),
                              child: buildImageWidget(imagePath),
                            );
                          },
                        )
                      : const Text('No evidence provided'),
                ],
              ),
            ),
    );
  }

  Widget buildImageWidget(String imagePath) {
    String imageUrl = replaceLocalhostWithIP(imagePath);
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('${widget.username}:${widget.password}'));

    return Image.network(
      imageUrl,
      height: 200,
      fit: BoxFit.cover,
      headers: {'Authorization': basicAuth},
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey,
          child: const Center(
            child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoViewGallery.builder(
            itemCount: _requestDetails!['imagePaths'].length,
            builder: (context, index) {
              String imagePath = replaceLocalhostWithIP(_requestDetails!['imagePaths'][index]['imagePath']);
              String basicAuth = 'Basic ' +
                  base64Encode(utf8.encode('${widget.username}:${widget.password}'));

              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(
                  imagePath,
                  headers: {'Authorization': basicAuth},
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            pageController: PageController(initialPage: index),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
            ),
          ),
        );
      },
    );
  }
}
