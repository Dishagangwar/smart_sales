import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  String? selectedType; // New variable to track the selected type
  bool isLoading = false;
  
  // The allowed types as per the backend documentation
  final List<String> categoryTypes = [
    "hardware", 
    "paints", 
    "sanitary", 
    "marbles", 
    "stationary", 
    "others"
  ];

  Future<void> handleCreateCategory() async {
    // 1. UI Validation: Prevent empty submissions
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category name is required")),
      );
      return;
    }

    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category type")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. Fetch required state data from storage (Simpler)
      final storage = StorageService();
      final token = await storage.getToken();

      // 3. Safety Check: Handle context across async gap
      if (!mounted) return;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please login again.")),
        );
        return;
      }

      print("DEBUG TOKEN: $token"); // Debug to ensure token is sent

      // 5. Protected API Call: Send token directly without frontend role check
      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/categories"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "description": descController.text.trim(),
          "type": selectedType, // Reverting type array back to string as per simple fix request
        }),
      );

      final data = jsonDecode(response.body);
      print("DEBUG API RESPONSE: $data | Status Code: ${response.statusCode}"); 

      if (!mounted) return;
      
      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Category created successfully"),
          ),
        );
        Navigator.pop(context);
      } else {
        // Any error logic (including 403) from the backend is handled here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to create category (Status: ${response.statusCode})"),
          ),
        );
      }
      
    } catch (e) {
      print("FULL ERROR: $e"); 
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
        title: const Text("Create Category"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: "Category Type",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.merge_type_outlined),
              ),
              items: categoryTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.toUpperCase()), // Capitalize for better look
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue;
                });
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Category Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: handleCreateCategory,
                    child: const Text(
                      "Create Category",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }
}
