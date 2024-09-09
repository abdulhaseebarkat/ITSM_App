import 'package:flutter/material.dart';
class RMInfo extends StatefulWidget{
  final String officerId;
  final String officerName;
  const RMInfo({
    Key? key,
    required this.officerId,
    required this.officerName,
  }) : super(key: key);
  @override
  State<RMInfo> createState() => _RMInfo();
}

class _RMInfo extends State<RMInfo> {
    final List<String> _faultNatures = ['ESU-BLN-03628',
'ESU-BLN-03610',
'ESU-BLN-03229',
'ESU-BLN-03608',
'ESU-BLN-03227',
'ESU-BLN-03605',
'ESU-BLN-03559',
'ESU-BLN-03558',
'ESU-BLN-03623',
'ESU-BLN-03624',
'ES2-BLN-05845',
'ESU-BLN-03233',
'ESU-BLN-03617',
'ESU-BLN-03551'];
    String? _selectedFaultNature;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets verified from TGL'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Site ID',
                border: OutlineInputBorder(),
              ),
              value: _selectedFaultNature,
              items: _faultNatures
                  .map((nature) => DropdownMenuItem<String>(
                        value: nature,
                        child: Text(nature),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFaultNature = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Evidence',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Wrap GridView.builder with Expanded to provide bounded height
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of images in each row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: 2, // Replace with actual item count
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.grey[300], // Placeholder for images
                    child: Center(
                      child: Text(
                        'Image ${index + 1}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Approve button logic here
                  },
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Reject button logic here
                  },
                  child: const Text('Forward to PM'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Reject button logic here
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      )
    );
  }
}