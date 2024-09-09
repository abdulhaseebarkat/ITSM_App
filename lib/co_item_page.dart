import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  

class COItemPage extends StatefulWidget {
  const COItemPage({super.key});

  @override
  State<COItemPage> createState() => _COItemPage();
}

class _COItemPage extends State<COItemPage> {
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
  bool _spareRequired = false;
  bool _cashRequired = false;
  XFile? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = pickedImage;
    });
  }

  void _submitForm() {
    // Perform your form submission logic here
    /*print('Form submitted');
    print('Site ID: ${_selectedFaultNature}');
    print('Spare Required: $_spareRequired');
    print('Cash Required: $_cashRequired');*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO Dashboard', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site ID Dropdown
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
            const SizedBox(height: 16),

            // Fault Nature Text Field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fault Nature',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Evidence Label and Camera Access
            const Text(
              'Evidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey[700],
                      ),
                    )
                  : Image.file(
                      File(_image!.path),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),

            // Spare Required Checkbox
            CheckboxListTile(
              title: const Text('Spare Required'),
              value: _spareRequired,
              onChanged: (bool? value) {
                setState(() {
                  _spareRequired = value ?? false;
                });
              },
            ),

            // Cash Required Checkbox
            CheckboxListTile(
              title: const Text('Cash Required'),
              value: _cashRequired,
              onChanged: (bool? value) {
                setState(() {
                  _cashRequired = value ?? false;
                });
              },
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}