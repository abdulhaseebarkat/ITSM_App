import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SparesDetailsPage extends StatefulWidget {
  final int id;
  final int requestId;
  final String username;
  final String fullName;
  final String role;
  final String password;

  const SparesDetailsPage({
    Key? key,
    required this.id,
    required this.requestId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.password,
  }) : super(key: key);

  @override
  State<SparesDetailsPage> createState() => _SparesDetailsPageState();
}

class _SparesDetailsPageState extends State<SparesDetailsPage> {
  final List<Map<String, String>> spares = [
    {"Item Code": "28000005722", "Item Name": "Engine Oil", "Unit": "Liters"},
    {"Item Code": "15100000454", "Item Name": "Battery 12V", "Unit": "Nos"},
    {"Item Code": "28000002604", "Item Name": "Radiator 30KVA Perkins", "Unit": "Nos"},
    {"Item Code": "15020200153", "Item Name": "Magnetic Contactor", "Unit": "Nos"},
    {"Item Code": "15040100035", "Item Name": "Control Cable", "Unit": "Meter"},
  ];

  List<Map<String, dynamic>> selectedSpares = [
    {
      "Item Name": null,
      "Item Code": TextEditingController(),
      "Unit": TextEditingController(),
      "Quantity": TextEditingController(text: "1"),
    }
  ];

  void _addNewSpare() {
    setState(() {
      selectedSpares.add({
        "Item Name": null,
        "Item Code": TextEditingController(),
        "Unit": TextEditingController(),
        "Quantity": TextEditingController(text: "1"),
      });
    });
  }

  void _updateSpare(int index, String? selectedItemName) {
    final spare = spares.firstWhere((s) => s["Item Name"] == selectedItemName, orElse: () => {});
    setState(() {
      selectedSpares[index]["Item Name"] = selectedItemName;
      selectedSpares[index]["Item Code"].text = spare["Item Code"] ?? "";
      selectedSpares[index]["Unit"].text = spare["Unit"] ?? "";
    });
  }

  void _removeSpare(int index) {
    setState(() {
      selectedSpares.removeAt(index);
    });
  }

  Future<void> _submitSpares() async {
    List<Map<String, dynamic>> result = selectedSpares.map((spare) {
      return {
        "Item Name": spare["Item Name"],
        "Item Code": spare["Item Code"].text,
        "Unit": spare["Unit"].text,
        "Quantity": spare["Quantity"].text,
      };
    }).toList();

    print("Selected Spares: $result");

    // Construct the request payload
    final requestPayload = {
      "spares": result,
    };

    // Send the updated request to the backend API
    final String apiUrl = "http://13.49.230.203:8080/api/request/${widget.requestId}"; // Using the correct endpoint
    try {
      String basicAuth = 'Basic ' +
          base64Encode(utf8.encode('${widget.username}:${widget.password}'));
      var headers = {'Authorization': basicAuth, 'Content-Type': 'application/json'};

      var response = await http.put(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(requestPayload),
      );

      if (response.statusCode == 200) {
        // Successfully updated the request with spares
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spares submitted successfully')));
        Navigator.pop(context); // Go back after successful submission
      } else {
        // Handle error
        print("Failed to update spares: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit spares')));
      }
    } catch (e) {
      print("Error submitting spares: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error submitting spares')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Spares Details")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...List.generate(selectedSpares.length, (index) {
              final spare = selectedSpares[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: spare["Item Name"],
                        decoration: const InputDecoration(labelText: "Select Spare"),
                        items: spares.map((s) {
                          return DropdownMenuItem(
                            value: s["Item Name"],
                            child: Text(s["Item Name"]!),
                          );
                        }).toList(),
                        onChanged: (value) => _updateSpare(index, value),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: spare["Item Code"],
                        decoration: const InputDecoration(labelText: "Item Code"),
                        readOnly: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: spare["Unit"],
                        decoration: const InputDecoration(labelText: "Unit"),
                        readOnly: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: spare["Quantity"],
                        decoration: const InputDecoration(labelText: "Quantity"),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      if (selectedSpares.length > 1)
                        TextButton(
                          onPressed: () => _removeSpare(index),
                          child: const Text("Remove Spare"),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewSpare,
              icon: const Icon(Icons.add),
              label: const Text("Add Spare"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitSpares,
              child: const Text("Submit Spares"),
            ),
          ],
        ),
      ),
    );
  }
}
