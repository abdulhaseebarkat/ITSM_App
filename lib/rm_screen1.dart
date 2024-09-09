import 'package:flutter/material.dart';
import 'package:telecom_app/rm_info.dart';

class RMList extends StatelessWidget {
  RMList({super.key});
  final List<Map<String, String>> groupLeads = [
    {'name': 'Haseeb2', 'id': 'TGL1'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Leads', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: ListView.builder(
        itemCount: groupLeads.length,
        itemBuilder: (context, index) {
          final officer = groupLeads[index];
          return ListTile(
            title: Text('${officer['id']!}    ${officer['name']!}'),
            trailing: ElevatedButton(onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => RMInfo(
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