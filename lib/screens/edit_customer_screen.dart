import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> initialData;

  const EditCustomerScreen({super.key, required this.customerId, required this.initialData});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController streetController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController pincodeController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final address = widget.initialData['address'] ?? {};
    
    nameController = TextEditingController(text: widget.initialData['name']);
    mobileController = TextEditingController(text: widget.initialData['mobile']);
    streetController = TextEditingController(text: address['street']);
    cityController = TextEditingController(text: address['city']);
    stateController = TextEditingController(text: address['state']);
    pincodeController = TextEditingController(text: address['pincode']);
  }

  Future<void> handleUpdateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await StorageService().getToken();
      if (!mounted) return;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No token found. Please login.")));
        setState(() => isLoading = false);
        return;
      }

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

      final response = await http.patch(
        Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer updated successfully!")));
        Navigator.pop(context, true); // Return success to refresh profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Failed to update customer")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Customer"),
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
                   const Text("Contact Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Customer Name *", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    validator: (value) => value!.isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(labelText: "Mobile Number *", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone), counterText: ""),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Mobile is required";
                      if (value.length < 10) return "Must be 10 digits";
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  const Text("Address Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: streetController,
                    decoration: const InputDecoration(labelText: "Street Address", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: const InputDecoration(labelText: "State", border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pincode", border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_post_office)),
                  ),

                  const SizedBox(height: 40),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: handleUpdateCustomer,
                          child: const Text("Update Customer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
