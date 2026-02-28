import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> categoryData;

  const EditCategoryScreen({super.key, required this.categoryData});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController nameController;
  late TextEditingController descController;
  
  String? selectedType;
  bool isLoading = false;

  final List<String> categoryTypes = [
    "hardware", 
    "paints", 
    "sanitary", 
    "marbles", 
    "stationary", 
    "others"
  ];

  @override
  void initState() {
    super.initState();
    // Prefill form from passed data
    nameController = TextEditingController(text: widget.categoryData['name'] ?? '');
    descController = TextEditingController(text: widget.categoryData['description'] ?? '');
    
    // Safety check for valid type assignment
    String initialType = (widget.categoryData['type'] ?? '').toString().toLowerCase();
    
    if (categoryTypes.contains(initialType)) {
      selectedType = initialType;
    } else {
      // The API initially used "paint", but the Create screen uses "paints" in the dropdown list
      // So let's handle the loose alias mapping directly for a better UX.
      if (initialType == 'paint') selectedType = 'paints';
      else if (initialType == 'marble') selectedType = 'marbles';
    }
  }

  Future<void> handleUpdateCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category type")),
      );
      return;
    }

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

      final String id = widget.categoryData['_id'];
      
      // Build the Partial Patch Body
      final bodyData = {
        "name": nameController.text.trim(),
        "type": selectedType,
      };

      // Only add description if it's changing logically
      if (descController.text.trim().isNotEmpty) {
        bodyData["description"] = descController.text.trim();
      }

      final response = await http.patch(
        Uri.parse("https://chamanmarblel.onrender.com/api/categories/$id"),
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
          const SnackBar(content: Text("Category updated successfully!")),
        );
        Navigator.pop(context, true); // Return true to signal a refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to update category")),
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
        title: const Text("Edit Category"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100)
                  ),
                  child: Text(
                    "Editing Category ID:\n${widget.categoryData['_id']}",
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Category Name *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: "Category Type *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: categoryTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedType = newValue;
                    });
                  },
                  validator: (value) => value == null ? "Required" : null,
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                
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
                        onPressed: handleUpdateCategory,
                        child: const Text(
                          "Update Category",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
              ],
            ),
          ),
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
