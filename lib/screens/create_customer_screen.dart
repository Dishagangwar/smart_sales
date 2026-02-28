import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  bool isLoading = false;

  Future<void> handleCreateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final storage = StorageService();
      final token = await storage.getToken();

      if (!mounted) return;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please login again.")),
        );
        return;
      }

      // Build nested JSON payload per API spec
      final bodyData = {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim(),
        "address": {
          "street": streetController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
        }
      };

      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/customers"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer created successfully!")),
        );
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to create customer")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Customer"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Contact Info ---
                  const Text("Contact Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name *", 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? "Name is required" : null,
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
                      counterText: "", // Hide character counter
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Mobile number is required";
                      if (value.length < 10) return "Must be 10 digits";
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // --- Address Block ---
                  const Text("Address Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: streetController,
                    decoration: const InputDecoration(
                      labelText: "Street Address *", 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => value!.isEmpty ? "Street address is required" : null,
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(labelText: "City *", border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? "City is required" : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: const InputDecoration(labelText: "State *", border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? "State is required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Pincode *", 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_post_office),
                    ),
                    validator: (value) => value!.isEmpty ? "Pincode is required" : null,
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: handleCreateCustomer,
                          child: const Text(
                            "Save Customer",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.dispose();
  }
}
