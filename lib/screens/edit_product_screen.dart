import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategoryId;
  
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController costPriceController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController(); // Renamed from sellingPriceController

  bool isLoading = true; // start loading until product and categories are fetched
  bool isSaving = false;
  String _errorMessage = '';

  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProductDetails();
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No authentication token found. Please login again.';
          _isLoadingCategories = false;
        });
        return;
      }

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
        } else {
          setState(() {
            _errorMessage = 'Failed to load categories: ${decoded['message']}';
            _isLoadingCategories = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to fetch categories';
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network Error fetching categories: $e';
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchProductDetails() async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        setState(() {
          _errorMessage = 'No authentication token found. Please login again.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("https://chamanmarblel.onrender.com/api/products/${widget.productId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("DEBUG GET BY ID: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final product = decoded['data'];
          
          setState(() {
            nameController.text = product['name'] ?? '';
            // Handle categoryId correctly depending on whether it's an object or string
            _selectedCategoryId = product['categoryId'] is Map
                ? product['categoryId']['_id']
                : product['categoryId']?.toString();
          
            // Verify category exists in dropdown, else set to null to avoid error
            if (_selectedCategoryId != null) {
              // Wait for categories to load if not already loaded
              if (_isLoadingCategories) {
                // This might cause a slight delay if product details load faster than categories
                // A more robust solution might involve combining the loading states or
                // re-evaluating _selectedCategoryId after categories are loaded.
                // For now, we assume categories will be loaded shortly after.
              }
              bool exists = _categories.any((cat) => cat['_id'] == _selectedCategoryId);
              if (!exists && !_isLoadingCategories) {
                 _selectedCategoryId = null; // Prevent Dropdown render crash if ID missing from fast load list
              }
            }

            companyController.text = product['company'] ?? '';
            skuController.text = product['sku'] ?? '';
            unitController.text = product['unit'] ?? '';
            costPriceController.text = (product['costPrice'] ?? 0).toString();
            purchasePriceController.text = (product['defaultSellingPrice'] ?? 0).toString(); // Using purchasePriceController
            
            isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load product details: ${decoded['message']}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to fetch product details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> handleUpdateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isSaving = true);

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

      final cost = double.tryParse(costPriceController.text.trim()) ?? 0.0;
      final selling = double.tryParse(purchasePriceController.text.trim()) ?? 0.0; // Using purchasePriceController

      final Map<String, dynamic> bodyData = {
        "name": nameController.text.trim(),
        "categoryId": _selectedCategoryId,
        "company": companyController.text.trim().isNotEmpty ? companyController.text.trim() : null,
        "sku": skuController.text.trim().isNotEmpty ? skuController.text.trim() : null,
        "unit": unitController.text.trim(),
        "costPrice": cost,
        "defaultSellingPrice": selling
      };

      final response = await http.patch(
        Uri.parse("https://chamanmarblel.onrender.com/api/products/${widget.productId}"),
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
          const SnackBar(content: Text("Product updated successfully!")),
        );
        Navigator.pop(context, true); // Return true to indicate change
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to update product")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _isLoadingCategories) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Product"), backgroundColor: Colors.blue),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Product"), backgroundColor: Colors.blue),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      _isLoadingCategories = true;
                      _errorMessage = '';
                    });
                    _fetchCategories();
                    _fetchProductDetails();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
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
                        controller: purchasePriceController, // Using purchasePriceController
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
                isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: handleUpdateProduct,
                        child: const Text(
                          "Save Changes",
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
    purchasePriceController.dispose(); // Using purchasePriceController
    super.dispose();
  }
}

