import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/customer_profile_screen.dart'; // We will create this next

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<dynamic> _customers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination & Search
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;
  String _searchQuery = "";
  bool _showDeleted = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication required";
          _isLoading = false;
        });
        return;
      }

      // Use dedicated endpoint for deleted customers
      final baseUrl = _showDeleted 
          ? "https://chamanmarblel.onrender.com/api/customers/deleted/list"
          : "https://chamanmarblel.onrender.com/api/customers";
          
      final urlStr = "$baseUrl?page=$page&limit=$_limit&search=$_searchQuery";
      final url = Uri.parse(urlStr);

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("DEBUG CUSTOMER LIST: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _customers = decoded['data'] ?? [];
            _totalPages = decoded['totalPages'] ?? 1;
            if (_currentPage > _totalPages && _totalPages > 0) {
                _currentPage = _totalPages;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = decoded['message'] ?? "Failed to load customers";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error ${response.statusCode}: Failed to fetch customers";
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1; // Reset to first page
        });
        _fetchCustomers(page: 1);
      }
    });
  }

  // Reloads the list after popping back from creation
  Future<void> _navigateAndRefresh(BuildContext context, String route) async {
    final result = await Navigator.pushNamed(context, route);
    if (result == true) {
      _fetchCustomers(page: _currentPage);
    }
  }
  
  // Go to details screen
  Future<void> _goToCustomerDetails(String id) async {
    // Navigate to profile screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerProfileScreen(customerId: id)),
    );
    // Refresh when popping back just in case balance changed
    _fetchCustomers(page: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _navigateAndRefresh(context, '/createCustomer'),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Create Customer",
      ),
      body: Column(
        children: [
          _buildHeader(),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- Search Bar ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search),
                        hintText: "Search name or mobile...",
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged("");
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Show Deleted Toggle ---
                  SwitchListTile(
                    title: const Text("Show Deleted Customers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    value: _showDeleted,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setState(() {
                        _showDeleted = val;
                        _currentPage = 1;
                      });
                      _fetchCustomers(page: 1);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 5),

                  // --- List Content ---
                  Expanded(
                    child: _isLoading && _customers.isEmpty // Showing initial load
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty && _customers.isEmpty
                            ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                            : _customers.isEmpty
                                ? const Center(child: Text("No customers found.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                                : ListView.builder(
                                    itemCount: _customers.length,
                                    itemBuilder: (context, index) {
                                      final customer = _customers[index];
                                      return _buildCustomerCard(customer);
                                    },
                                  ),
                  ),

                  // --- Pagination Controls ---
                  if (_totalPages > 1) _buildPaginationFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 && !_isLoading ? () => _fetchCustomers(page: _currentPage - 1) : null,
          ),
          Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages && !_isLoading ? () => _fetchCustomers(page: _currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Customer Details",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    num balance = 0;
    if (customer['currentBalance'] != null) {
      final cb = customer['currentBalance'];
      balance = cb is num ? cb : num.tryParse(cb.toString()) ?? 0;
    }

    num lifetimeSales = 0;
    if (customer['totalLifetimeSales'] != null) {
      final ts = customer['totalLifetimeSales'];
      lifetimeSales = ts is num ? ts : num.tryParse(ts.toString()) ?? 0;
    }
    
    // Per spec: Balance badge (red if > 0)
    final bool hasDebt = balance > 0;

    return GestureDetector(
      onTap: () => _goToCustomerDetails(customer['_id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name and Mobile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customer['name'] ?? "Unknown",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  customer['mobile'] ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Row 2: Finances
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Finance Metrics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showDeleted)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                         child: const Text("DELETED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                       )
                    else ...[
                      const Text("Lifetime Sales", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("₹${lifetimeSales.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ]
                  ],
                ),
                
                // Current Balance Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasDebt ? Colors.red.shade200 : Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDebt ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        size: 16,
                        color: hasDebt ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Bal: ₹${balance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}