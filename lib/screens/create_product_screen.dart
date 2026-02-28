import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Use a string variable for category instead of a controller
  String? _selectedCategoryId;
  
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController costPriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController(); // Kept as sellingPriceController
  final TextEditingController purchasePriceController = TextEditingController(); // Added based on dispose in instruction

  bool isLoading = false;
  
  // Categories for the dropdown
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await StorageService().getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/categories/dropdown/list");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _categories = decoded['data'] ?? [];
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
      print("Error fetching categories: $e");
    }
  }

  Future<void> handleCreateProduct() async {
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
        setState(() => isLoading = false);
        return;
      }

      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Category")),
        );
        setState(() => isLoading = false);
        return;
      }

      final cost = double.tryParse(costPriceController.text.trim()) ?? 0.0;
      final selling = double.tryParse(sellingPriceController.text.trim()) ?? 0.0;

      final Map<String, dynamic> bodyData = {
        "name": nameController.text.trim(),
        "categoryId": _selectedCategoryId,
        "company": companyController.text.trim().isNotEmpty ? companyController.text.trim() : null,
        "sku": skuController.text.trim().isNotEmpty ? skuController.text.trim() : null,
        "unit": unitController.text.trim(),
        "costPrice": cost,
        "defaultSellingPrice": selling,
      };

      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/products"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      final data = jsonDecode(response.body);
      print("DEBUG API RESPONSE Product: $data | Status Code: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product created successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to create product")),
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
        title: const Text("Add Product"),
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
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Product Name *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 15),
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: "Category *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map<DropdownMenuItem<String>>((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['_id'],
                            child: Text(cat['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (value) => value == null ? "Please select a Category" : null,
                      ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: "Company (Optional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: skuController,
                  decoration: const InputDecoration(
                    labelText: "SKU / Barcode (Optional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: "Unit (e.g. kg, liter, pcs) *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Cost Price *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Required";
                          if (double.tryParse(value) == null) return "Invalid";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Selling Price *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sell),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Required";
                          if (double.tryParse(value) == null) return "Invalid";
                          return null;
                        },
                      ),
                    ),
                  ],
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
                        onPressed: handleCreateProduct,
                        child: const Text(
                          "Create Product",
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
    companyController.dispose();
    skuController.dispose();
    unitController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose(); // Kept as sellingPriceController
    purchasePriceController.dispose(); // Added based on dispose in instruction
    super.dispose();
  }
}
