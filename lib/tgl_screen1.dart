import 'package:flutter/material.dart';
import 'package:telecom_app/fault_detail_screen.dart';

class COList extends StatelessWidget {
  COList({super.key});
  final List<Map<String, String>> clusterOfficers = [
    {'name': 'Haseeb1', 'id': 'CO1'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cluster Officers', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: ListView.builder(
        itemCount: clusterOfficers.length,
        itemBuilder: (context, index) {
          final officer = clusterOfficers[index];
          return ListTile(
            title: Text('${officer['id']!}    ${officer['name']!}'),
            trailing: ElevatedButton(onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => FaultDetailScreen(
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