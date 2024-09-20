import 'package:flutter/material.dart';
import 'package:telecom_app/pm_info.dart';

class PMList extends StatelessWidget {
  final int id;
  final String username;
  final String fullName;
  final String role;
  PMList({super.key, required this.id, required this.username, required this.fullName, required this.role});
  final List<Map<String, String>> rMlist = [
    {'name': 'Haseeb3', 'id': 'RM1'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Managers', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: ListView.builder(
        itemCount: rMlist.length,
        itemBuilder: (context, index) {
          final officer = rMlist[index];
          return ListTile(
            title: Text('${officer['id']!}    ${officer['name']!}'),
            trailing: ElevatedButton(onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => PMInfo(
                officerId: officer['id']!,
                officerName: officer['name']!,
              )
            )
          );
          }, child: const Text('View Tickets')
            ),
            
          );
        },
      ), 
    );
  }
}