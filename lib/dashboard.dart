import 'package:flutter/material.dart';
import 'package:telecom_app/co_item_page.dart';
import 'package:telecom_app/pm_screen1.dart';
import 'package:telecom_app/rm_screen1.dart';
import 'package:telecom_app/tgl_screen1.dart';

class DashboardPage extends StatelessWidget {
  final int id;
  final String username;
  final String role;
  final String fullName;
  final String password;
  const DashboardPage({super.key, required this.username,required this.id, required this.fullName, required this.role, required this.password});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('0',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                      
                      ),
                      Text('DONE'),
                      SizedBox(height: 8,),
                      Text('0',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                      ),
                      Text('NOT DONE'),
                      SizedBox(height: 10,),
                      Text('Corrective Maintenance',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.lightBlue
                      ),
                      //onPressed: 
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Card(
                    elevation: 10,
                    child: Padding(padding: const EdgeInsets.all(10.0),
                    child: IconButton(
  onPressed: () {
    if (role == 'CO') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => COItemPage(
          id: id,
          username: username,
          fullName: fullName,
          role: role,
          password: password,
        )),
      );
    } else if (role == 'TGL') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => COList(
           id: id,
          username: username,
          fullName: fullName,
          role: role,
        )),
      );
    } else if (role == 'RM') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => RMList(
           id: id,
          username: username,
          fullName: fullName,
          role: role,
        )),
      );
    } else if (role == 'PM') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PMList(
           id: id,
          username: username,
          fullName: fullName,
          role: role,
        )),
      );
    }
  },
  icon: const Icon(Icons.build, color: Colors.blue),
)
,
                    ),
                  ),
                  const SizedBox(height: 5,),
                  const Text('CM',
                  style: TextStyle(color: Colors.blue),
                  )
                ],
              )
            ),
          ],
        ),

      )
    );
  }
}