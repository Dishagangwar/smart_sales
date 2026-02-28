import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';

class CreatePainterScreen extends StatefulWidget {
  @override
  State<CreatePainterScreen> createState() => _CreatePainterScreenState();
}

class _CreatePainterScreenState extends State<CreatePainterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  bool isLoading = false;

  Future<void> _createPainter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication required")),
          );
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final bodyData = {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim(),
        "role": "PAINTER", // Fixed as per API contract
      };

      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/painters"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 || (response.statusCode == 200 && decoded['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Painter created successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to trigger refresh on previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? "Failed to create painter")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
           isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Painter"),
        backgroundColor: Colors.indigo, // Visual distinction for Painter Module
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Painter Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Painter Name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_paint),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter painter name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Mobile Number *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  counterText: "",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter mobile number";
                  }
                  if (value.length != 10) {
                    return "Mobile must be 10 digits";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading ? null : _createPainter,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Painter",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
