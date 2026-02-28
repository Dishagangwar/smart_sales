import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/common_widgets.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

class NewBillStep2 extends StatefulWidget {
  @override
  State<NewBillStep2> createState() => _NewBillStep2State();
}

class _NewBillStep2State extends State<NewBillStep2> {
  // --- Data State ---
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  
  // --- Form State ---
  String? _selectedCategoryId;
  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final TextEditingController _painterCommissionController = TextEditingController();

  // --- Bill State ---
  List<Map<String, dynamic>> _billItems = []; // List of items added to the current bill

  // --- Loading / Error State ---
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;
  bool _isLoadingCheckout = false; // Added checkout state
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // 1. Fetch Categories for the first dropdown
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No auth token. Please login.";
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
            _errorMessage = "Failed to load categories: ${decoded['message']}";
            _isLoadingCategories = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load categories (Status: ${response.statusCode})";
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network Error: $e";
        _isLoadingCategories = false;
      });
    }
  }

  // 2. Fetch Products for a specific category
  Future<void> _fetchProductsForCategory(String categoryId) async {
    setState(() {
      _isLoadingProducts = true;
      _products = [];
      _selectedProduct = null;
    });

    try {
      final token = await StorageService().getToken();
      
      final response = await http.get(
        // Required API endpoint from documentation
        Uri.parse("https://chamanmarblel.onrender.com/api/products/dropdown/list?categoryId=$categoryId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("DEBUG DROPDOWN FETCH: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          setState(() {
            _products = decoded['data'];
            _isLoadingProducts = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load products for category"))
        );
        setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: $e"))
      );
      setState(() => _isLoadingProducts = false);
    }
  }

  // 3. Add to local bill list
  void _addProductToBill() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product first")),
      );
      return;
    }

    int qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity greater than 0")),
      );
      return;
    }

    String name = _selectedProduct!['name'] ?? 'Unknown';
    String unit = _selectedProduct!['unit'] ?? 'pcs';
    num price = _selectedProduct!['defaultSellingPrice'] ?? 0;
    num costPrice = _selectedProduct!['costPrice'] ?? 0;
    String productId = _selectedProduct!['_id'] ?? '';
    
    // The API might return category as an object (with _id) OR as a raw string ID. 
    // Defaulting to "" crashes the backend's ObjectId parser. We must use null if empty.
    String? categoryId;
    if (_selectedProduct!['category'] != null) {
        if (_selectedProduct!['category'] is Map) {
            categoryId = _selectedProduct!['category']['_id'];
        } else {
            categoryId = _selectedProduct!['category'].toString();
        }
    }

    setState(() {
      _billItems.add({
        "productId": productId,
        "categoryId": categoryId,
        "name": name,
        "unit": unit,
        "price": price,
        "costPrice": costPrice,
        "quantity": qty,
        "total": price * qty,
      });

      // Reset selection for next item
      _selectedProduct = null;
      _quantityController.text = "1";
    });
  }

  // 4. Calculate Grand Total
  double get _grandTotal {
    double total = 0;
    for (var item in _billItems) {
      total += item['total'];
    }
    return total;
  }

  Future<void> _proceedToPayment(Map<String, dynamic>? args) async {
    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one item to the bill!")));
      return;
    }

    setState(() => _isLoadingCheckout = true);

    try {
      final token = await StorageService().getToken();
      if (token == null) throw Exception("No authentication token found");

      // Construct identical payload to API contract
      final customerData = args?['customer'];
      final customerId = customerData != null ? customerData['_id'] : null;

      if (customerId == null) {
        throw Exception("Missing Customer ID from Step 1");
      }

      // Resolve Painter ID
      String? resolvedPainterId = args?['painterId'];
      
      // AUTO-CREATE PAINTER FEATURE: If no ID exists but a name was typed, create the Painter!
      if (resolvedPainterId == null && args?['painterName'] != null) {
          final String fakeMobile = DateTime.now().millisecondsSinceEpoch.toString().substring(3);
          final painterResponse = await http.post(
             Uri.parse("https://chamanmarblel.onrender.com/api/painters"),
             headers: {
               "Content-Type": "application/json",
               "Authorization": "Bearer $token",
             },
             body: jsonEncode({
               "name": args!['painterName'],
               "mobile": fakeMobile,
               "role": "PAINTER",
             }),
          );
          
          if (painterResponse.statusCode == 201 || painterResponse.statusCode == 200) {
              final pDecoded = jsonDecode(painterResponse.body);
              if (pDecoded['success'] == true) {
                 resolvedPainterId = pDecoded['data']['_id'];
                 print("AUTO-CREATED PAINTER: $resolvedPainterId");
              }
          } else {
              print("FAILED TO AUTO-CREATE PAINTER: ${painterResponse.statusCode} - ${painterResponse.body}");
          }
      }

      final Map<String, dynamic> payload = {
        "billNumber": "DRAFT_${DateTime.now().millisecondsSinceEpoch}", // Backend strict requirement
        "customerId": customerId,
        "paymentMode": "CASH", // Default for draft
        "paidAmount": 0,
        "discount": 0,
        "tax": 0,
        "lineItems": _billItems.map((item) {
           final Map<String, dynamic> lineItem = {
              "productId": item['productId'],
              "name": item['name'],
              "quantity": item['quantity'],
              "costPrice": item['costPrice'],
              "sellingPrice": item['price'],
           };
           // Only include categoryId if it's a valid string. Prevent empty strings.
           if (item['categoryId'] != null && item['categoryId'].toString().isNotEmpty) {
               lineItem['categoryId'] = item['categoryId'];
           }
           return lineItem;
        }).toList(),
      };

      // If Painter linked (either pre-existing OR just auto-created above), map snapshot
      if (resolvedPainterId != null) {
         final double parsedCommission = double.tryParse(_painterCommissionController.text.trim()) ?? 0;
         payload["painterSnapshot"] = {
           "painterId": resolvedPainterId,
           "commissionType": "AMOUNT", // Crucial: Set to AMOUNT so it treats commissionValue as raw cash
           "commissionValue": parsedCommission
         };
      }

      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/bills"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      print("DRAFT BILL RESPONSE: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
           final billId = decoded['data']['_id'];

           // Add the brand new Document ID to the arguments and jump to Step 3!
           if (mounted) {
             final Map<String, dynamic> step3Payload = {
               "billId": billId, // CRITICAL NEW ID
               "customer": customerData,
               "painterId": resolvedPainterId, // Pass the official ID, whether old or brand new
               "items": _billItems,
               "grandTotal": _grandTotal,
             };
             Navigator.pushNamed(context, '/bill3', arguments: step3Payload);
           }
        } else {
           throw Exception(decoded['message'] ?? "Unknown API Error");
        }
      } else {
         throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to Create Draft Bill: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isLoadingCheckout ? null : () => _proceedToPayment(args),
          child: _isLoadingCheckout 
             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
             : const Text("PROCEED TO PAYMENT", style: TextStyle(fontSize: 16)),
        ),
      ),
      body: Column(
        children: [
          buildHeader("New Bill", "Add a new Bill"),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- ADD PRODUCT SECTION ---
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.inventory_2, color: Colors.blue)
                    ],
                  ),
                  const SizedBox(height: 15),

                  if (_errorMessage.isNotEmpty)
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),

                  // CATEGORY DROPDOWN
                  if (_isLoadingCategories)
                    const Center(child: LinearProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Category",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategoryId,
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['_id'],
                          child: Text(cat['name'] ?? 'Unnamed Category'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                        if (val != null) {
                          _fetchProductsForCategory(val);
                        }
                      },
                    ),

                  const SizedBox(height: 15),

                  // PRODUCT DROPDOWN
                  if (_selectedCategoryId != null)
                    _isLoadingProducts
                        ? const Center(child: LinearProgressIndicator())
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: const InputDecoration(
                              labelText: "Select Product",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedProduct,
                            items: _products.map((prod) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: prod,
                                child: Text("${prod['name']} (₹${prod['defaultSellingPrice']}/${prod['unit']})"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProduct = val;
                              });
                            },
                          ),

                  const SizedBox(height: 15),

                  // QUANTITY & ADD BUTTON
                  if (_selectedProduct != null)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Qty",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: _addProductToBill,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text("Add to Bill", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),

                  const Divider(height: 40, thickness: 2),

                  // --- BILL ITEMS LIST ---
                  const Text("Current Bill", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _billItems.isEmpty
                        ? const Center(child: Text("No items added yet.", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _billItems.length,
                            itemBuilder: (context, index) {
                              final item = _billItems[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${item['name']} (${item['unit']}) x ${item['quantity']}",
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text("₹${item['total']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _billItems.removeAt(index);
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // --- PAINTER COMMISSION ---
                  if (args != null && (args['painterId'] != null || args['painterName'] != null)) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.indigo.shade100)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.format_paint, color: Colors.indigo, size: 20),
                              SizedBox(width: 8),
                              Text("Painter Commission", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _painterCommissionController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Commission Earned on this Bill",
                              hintText: "Enter total commission to add to balance...",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixText: "₹ "
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),

                  // --- GRAND TOTAL ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount", style: TextStyle(fontSize: 16)),
                        Text(
                          "₹${_grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}