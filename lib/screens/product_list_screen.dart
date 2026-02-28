import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/create_product_screen.dart';
import 'package:smart_sales/screens/edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showDeleted = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        setState(() {
          _errorMessage = 'No authentication token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final String url = _showDeleted 
          ? "https://chamanmarblel.onrender.com/api/products?page=1&limit=100&isDeleted=true"
          : "https://chamanmarblel.onrender.com/api/products?page=1&limit=100";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("DEBUG PRODUCT GET RES: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          setState(() {
            _products = decoded['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load products: ${decoded['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to fetch products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await StorageService().getToken();
      final response = await http.delete(
        Uri.parse("https://chamanmarblel.onrender.com/api/products/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted successfully")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete product")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreProduct(String id) async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService().getToken();
      final response = await http.patch(
        Uri.parse("https://chamanmarblel.onrender.com/api/products/$id/restore"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product restored successfully")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to restore product")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Catalog"),
        backgroundColor: Colors.blue,
        actions: [
          Row(
            children: [
              const Text("Deleted", style: TextStyle(fontSize: 12)),
              Switch(
                value: _showDeleted,
                activeColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _showDeleted = val;
                  });
                  _fetchProducts();
                },
              ),
            ],
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Wait for the Create Product screen to pop back, then refresh the list
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductScreen()),
          );
          _fetchProducts();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
                onPressed: _fetchProducts,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          "No products found.\nTap the + button to create one.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final String name = product['name'] ?? 'Unknown Product';
        final String unit = product['unit'] ?? 'N/A';
        final String company = product['company'] ?? 'N/A';
        final num sellingPrice = product['defaultSellingPrice'] ?? 0;
        final num costPrice = product['costPrice'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.inventory_2, color: Colors.blue),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Company: $company | Unit: $unit"),
                  const SizedBox(height: 4),
                  Text("Cost: ₹$costPrice"),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹$sellingPrice",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                if (_showDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.blue),
                    onPressed: () => _restoreProduct(product['_id']),
                    tooltip: "Restore",
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProductScreen(productId: product['_id'])),
                        );
                        if (result == true) _fetchProducts();
                      } else if (value == 'delete') {
                        _deleteProduct(product['_id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
