import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/edit_customer_screen.dart';
import 'package:smart_sales/screens/customer_ledger_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;

  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      final role = await StorageService().getRole();
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication required";
          _isLoading = false;
        });
        return;
      }
      _userRole = role;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}");
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
            _customerData = decoded['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = decoded['message'] ?? "Failed to load profile";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error ${response.statusCode}: Failed to fetch profile";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Network Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEdit() async {
    if (_customerData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(
          customerId: widget.customerId,
          initialData: _customerData!,
        ),
      ),
    );
    if (result == true) {
      _fetchCustomerProfile(); // Refresh after edit
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Customer?"),
        content: const Text("Are you sure you want to delete this customer?"),
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
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}");
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer deleted successfully!")));
        Navigator.pop(context, true); // Return to list view
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to delete")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreCustomer() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService().getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}/restore");
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer restored successfully!")));
        Navigator.pop(context, true); // Return to list view
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to restore")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAdjustBalanceDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Adjust Balance"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "This creates a manual ADJUSTMENT ledger entry and forces a balance recalculation.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount (+ or -)",
                      hintText: "e.g., -200 to reduce debt",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Adjustment Note (Required)",
                      hintText: "Reason for manual edit",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amountText = amountController.text.trim();
                        final noteText = noteController.text.trim();

                        if (amountText.isEmpty || noteText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Amount and Note are required.")),
                          );
                          return;
                        }

                        final num? amount = num.tryParse(amountText);
                        if (amount == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Invalid amount format.")),
                          );
                          return;
                        }

                        setStateDialog(() => isSubmitting = true);

                        try {
                          final token = await StorageService().getToken();
                          final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}/adjust-balance");
                          
                          final response = await http.patch(
                            url,
                            headers: {
                              "Content-Type": "application/json",
                              "Authorization": "Bearer $token",
                            },
                            body: jsonEncode({
                              "amount": amount,
                              "note": noteText,
                            }),
                          );

                          final decoded = jsonDecode(response.body);

                          if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
                             if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Balance adjusted successfully!"), backgroundColor: Colors.green),
                                );
                                _fetchCustomerProfile(); 
                             }
                          } else {
                            setStateDialog(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(decoded['message'] ?? "Adjustment failed.")),
                              );
                            }
                          }
                        } catch (e) {
                          setStateDialog(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Profile"),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (_customerData != null && _customerData!['isDeleted'] != true)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
              tooltip: "Edit Customer",
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _customerData == null
                  ? const Center(child: Text("Customer not found"))
                  : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final address = _customerData?['address'] ?? {};
    
    // Robust parsing for balance and sales
    num balance = 0;
    if (_customerData?['currentBalance'] != null) {
      final cb = _customerData!['currentBalance'];
      balance = cb is num ? cb : num.tryParse(cb.toString()) ?? 0;
    }

    num totalSales = 0;
    if (_customerData?['totalLifetimeSales'] != null) {
      final ts = _customerData!['totalLifetimeSales'];
      totalSales = ts is num ? ts : num.tryParse(ts.toString()) ?? 0;
    }

    final bool hasDebt = balance > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card (Name & Mobile)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              children: [
                if (_customerData!['isDeleted'] == true)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(5)),
                    child: const Text("THIS CUSTOMER IS DELETED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _customerData!['name']?.substring(0, 1).toUpperCase() ?? "C",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _customerData!['name'] ?? "Unknown",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      _customerData!['mobile'] ?? "No Mobile",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Statistics Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Current Balance",
                  value: "₹${balance.toStringAsFixed(2)}",
                  icon: Icons.account_balance_wallet,
                  color: hasDebt ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: "Lifetime Sales",
                  value: "₹${totalSales.toStringAsFixed(2)}",
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          if (_userRole == 'SUPER_ADMIN') ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              icon: const Icon(Icons.build_circle),
              label: const Text("Adjust Balance (Super Admin)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _showAdjustBalanceDialog,
            ),
          ],

          const SizedBox(height: 15),

          // Ledger Access Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.blue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.receipt_long, color: Colors.blue),
            label: const Text("View Full Ledger", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerLedgerScreen(
                    customerId: widget.customerId,
                    customerName: _customerData!['name'] ?? "Customer",
                  ),
                ),
              ).then((_) {
                 // Refresh stats in case they were modified externally (like adding a bill inside the ledger later)
                 _fetchCustomerProfile(); 
              });
            },
          ),

          const SizedBox(height: 20),

          // Address Card (Nested JSON object handling)
          const Text("Address Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: address.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressRow(Icons.streetview, "Street", address['street']),
                      const Divider(height: 20),
                      _buildAddressRow(Icons.location_city, "City", address['city']),
                      const Divider(height: 20),
                      _buildAddressRow(Icons.map, "State", address['state']),
                      const Divider(height: 20),
                      _buildAddressRow(Icons.pin_drop, "Pincode", address['pincode']),
                    ],
                  )
                : const Text("No address on file", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
          
          if (_customerData!['isDeleted'] == true) ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.restore),
              label: const Text("Restore Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _restoreCustomer,
            ),
          ] else if (balance <= 0) ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _deleteCustomer,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 13, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value?.isEmpty ?? true ? 'N/A' : value!, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
