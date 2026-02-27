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
  bool isLoading = false;

  Future<void> handleCreateCategory() async {
    // 1. UI Validation: Prevent empty submissions
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category name is required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. Fetch required state data from storage
      final storage = StorageService();
      final token = await storage.getToken();
      final currentRole = await storage.getRole();

      // 3. Safety Check: Handle context across async gap
      if (!mounted) return;

      // 4. Role Validation: Check permissions before API call
      if (currentRole == "ADMIN" || currentRole == "SUPER_ADMIN") {
        // 5. Protected API Call: Authorization header is required
        final response = await http.post(
          Uri.parse("https://chamanmarblel.onrender.com/api/categories"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "name": nameController.text.trim(),
            "description": descController.text.trim(),
          }),
        );

        final data = jsonDecode(response.body);

        if (!mounted) return;
        if (response.statusCode == 201 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Category created successfully"),
          ),
        );
        Navigator.pop(context);
      }
      // Handle Forbidden errors specifically
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Forbidden: Unauthorized Role")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to create category"),
          ),
        );
      }
      }

      // 6. Response Handling: Align with Success Response documentation
      
    } catch (e) {
      print(
        "FULL ERROR: $e",
      ); // 👈 Isse console mein dekhein asli error kya hai
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ), // User ko bhi real error dikhayein debug ke liye
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
