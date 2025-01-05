import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telecom_app/co_item_page.dart';
import 'package:telecom_app/pm_screen1.dart';
import 'package:telecom_app/rm_screen1.dart';
import 'package:telecom_app/requests_list_page.dart';
import 'package:telecom_app/tgl_screen1.dart';
import 'package:telecom_app/co_requests_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final int id;
  final String username;
  final String role;
  final String fullName;
  final String password;

  const DashboardPage({
    Key? key,
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.password,
  }) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final String serverIp = 'http://13.49.230.203:8080';

  // CO request status counts
  int pendingCount = 0;
  int verifiedCount = 0;
  int approvedCount = 0;
  int declinedCount = 0;

  // Available requests for TGL, RM, and PM
  int availableRequests = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // if (widget.role == 'CO') {
    //   _fetchCORequests(); // Fetch CO request counts by status
    // } else if (widget.role == 'TGL' || widget.role == 'RM' || widget.role == 'PM') {
    //   _fetchRequestsForRole(); // Fetch available requests for TGL, RM, and PM
    // }
    _fetchDashboardData();
  }

    // Fetch all necessary data based on role
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    if (widget.role == 'CO') {
      await _fetchCORequests();
    } else if (widget.role == 'TGL' || widget.role == 'RM' || widget.role == 'PM') {
      await _fetchRequestsForRole();
    }
    setState(() => _isLoading = false);
  }



  // Fetch CO requests by status
  Future<void> _fetchCORequests() async {
    final String requestsEndpoint = '$serverIp/api/request/co/requests';

    try {
      var headers = {
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('${widget.username}:${widget.password}')),
      };

      var request = http.Request('GET', Uri.parse(requestsEndpoint));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        List<dynamic> requests = json.decode(responseBody);

        int pending = 0;
        int verified = 0;
        int approved = 0;
        int declined = 0;

        // Count requests by status
        for (var request in requests) {
          String status = request['status'];
          if (status == 'PENDING') {
            pending++;
          } else if (status == 'VERIFIED') {
            verified++;
          } else if (status == 'APPROVED') {
            approved++;
          } else if (status == 'DECLINED') {
            declined++;
          }
        }

        setState(() {
          pendingCount = pending;
          verifiedCount = verified;
          approvedCount = approved;
          declinedCount = declined;
        });
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch requests for TGL, RM, and PM based on their role
  Future<void> _fetchRequestsForRole() async {
    final String requestsEndpoint = '$serverIp/api/request/requests';

    try {
      var headers = {
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('${widget.username}:${widget.password}')),
      };

      var request = http.Request('GET', Uri.parse(requestsEndpoint));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        List<dynamic> requests = json.decode(responseBody);

        int count = 0;

        if (widget.role == 'TGL') {
          count = requests.where((request) => request['currentLevel'] == 'TGL').length;
        } else if (widget.role == 'RM') {
          count = requests.where((request) => request['currentLevel'] == 'RM').length;
        } else if (widget.role == 'PM') {
          count = requests.where((request) => request['currentLevel'] == 'PM').length;
        }

        setState(() {
          availableRequests = count;
        });
      } else {
        print('Error fetching requests: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _logout() async {
    final String logoutEndpoint = '$serverIp/public/api/auth/logout';

    try {
      var headers = {
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('${widget.username}:${widget.password}')),
      };

      var request = http.Request('GET', Uri.parse(logoutEndpoint));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print(await response.stream.bytesToString());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        print('Logout failed with status code: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: 
    RefreshIndicator(onRefresh: _fetchDashboardData,
    child: _isLoading
    ? const Center(child: CircularProgressIndicator()) : _buildDashboardContent(),
    ),
  );
}

Widget _buildDashboardContent(){
  return     Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.role == 'CO') _buildCODashboardCard(),
          if (widget.role == 'TGL' || widget.role == 'RM' || widget.role == 'PM') _buildRoleDashboardCard(),
          const SizedBox(height: 10),
          _buildActionCard(context),
          const SizedBox(height: 20),
          if (widget.role == 'CO') _buildCOTrackButton(context),
        ],
      ),
    );
}

// AppBar with logout button
AppBar _buildAppBar() {
  return AppBar(
    title: const Text('Dashboard'),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await _logout(); // Call the logout function when the logout icon is clicked
        },
      ),
    ],
  );
}

// CO Dashboard Card: Counts by Status
Widget _buildCODashboardCard() {
  return SizedBox(
    width: double.infinity,
    child: Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              pendingCount.toString(),
              style: const TextStyle(fontSize: 20),
            ),
            const Text('PENDING'),
            const SizedBox(height: 8),
            Text(
              verifiedCount.toString(),
              style: const TextStyle(fontSize: 20),
            ),
            const Text('VERIFIED'),
            const SizedBox(height: 8),
            Text(
              approvedCount.toString(),
              style: const TextStyle(fontSize: 20),
            ),
            const Text('APPROVED'),
            const SizedBox(height: 8),
            Text(
              declinedCount.toString(),
              style: const TextStyle(fontSize: 20),
            ),
            const Text('DECLINED'),
            const SizedBox(height: 10),
            const Text(
              'Corrective Maintenance',
              style: TextStyle(fontSize: 10, color: Colors.lightBlue),
            ),
          ],
        ),
      ),
    ),
  );
}

// TGL, RM, PM Dashboard Card: Available Requests
Widget _buildRoleDashboardCard() {
  return SizedBox(
    width: double.infinity,
    child: Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              availableRequests.toString(),
              style: const TextStyle(fontSize: 20),
            ),
            const Text('Available Requests'),
            const SizedBox(height: 10),
            const Text(
              'Corrective Maintenance',
              style: TextStyle(fontSize: 10, color: Colors.lightBlue),
            ),
          ],
        ),
      ),
    ),
  );
}

// Action Card for the role-specific navigation
Widget _buildActionCard(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Column(
        children: [
          Card(
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                onPressed: () {
                  _navigateBasedOnRole(context);
                },
                icon: const Icon(Icons.build, color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text('CM', style: TextStyle(color: Colors.blue)),
        ],
      ),
      const SizedBox(width: 20), // Space between icons
      if (widget.role == 'CO')
        Column(
          children: [
            Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: IconButton(
                  onPressed: () {
                    _navigateToSparesScreen(context);
                  },
                  icon: const Icon(Icons.construction, color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text('Spares', style: TextStyle(color: Colors.green)),
          ],
        ),
    ],
  );
}


// Button for CO to track their requests
Widget _buildCOTrackButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CORequestsPage(
              id: widget.id,
              username: widget.username,
              password: widget.password,
            ),
          ),
        );
      },
      icon: const Icon(Icons.track_changes),
      label: const Text('Track My Requests'),
    ),
  );
}

// Navigation logic based on role
void _navigateBasedOnRole(BuildContext context) {
  if (widget.role == 'CO') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => COItemPage(
          id: widget.id,
          username: widget.username,
          fullName: widget.fullName,
          password: widget.password,
          role: widget.role,
        ),
      ),
    );
  } else if (widget.role == 'TGL') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => COList(
          id: widget.id,
          username: widget.username,
          fullName: widget.fullName,
          role: widget.role,
          password: widget.password,
        ),
      ),
    );
  } else if (widget.role == 'RM') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RMList(
          id: widget.id,
          username: widget.username,
          fullName: widget.fullName,
          role: widget.role,
          password: widget.password,
        ),
      ),
    );
  } else if (widget.role == 'PM') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PMList(
          id: widget.id,
          username: widget.username,
          fullName: widget.fullName,
          role: widget.role,
          password: widget.password,
        ),
      ),
    );
  }
}

void _navigateToSparesScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RequestsListPage(
        id: widget.id,
        username: widget.username,
        fullName: widget.fullName,
        role: widget.role,
        password: widget.password,
      ),
    ),
  );
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDashboardData();
  }
}