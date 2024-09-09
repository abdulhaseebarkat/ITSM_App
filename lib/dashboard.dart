import 'package:flutter/material.dart';
import 'package:telecom_app/co_item_page.dart';
import 'package:telecom_app/pm_screen1.dart';
import 'package:telecom_app/rm_screen1.dart';
import 'package:telecom_app/tgl_screen1.dart';

class DashboardPage extends StatelessWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

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
                    child: IconButton(onPressed: () {
                     if(username == 'co@admin.com'){
                      Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const COItemPage()),
                            );
                     }
                     else if(username == 'tgl@admin.com'){
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => COList())
                        );
                     }
                     else if(username == 'rm@admin.com'){
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => RMList())
                      );
                     }
                     else if(username == 'pm@admin.com'){
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => PMList())
                      );
                     }
                    },
                    icon: const Icon(Icons.build, color: Colors.blue,),
                    ),
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