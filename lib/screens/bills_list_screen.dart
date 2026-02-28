import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/bill_details_screen.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  List<dynamic> _bills = [];
  bool _isLoading = true;
  String _error = '';

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  // Filters
  String _searchQuery = '';
  String _selectedStatus = 'ALL'; // ALL, COMPLETED, DRAFT, CREDIT, REFUNDED

  // Debouncing for search
  Timer? _debounceTimer;

  // To cleanly dispose timer
  // A local class to handle timer since we can't import async directly without warning if unused,
  // but we need it. Let's just import 'dart:async' properly at the top.
  
  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBills({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _error = "Authentication required";
          _isLoading = false;
        });
        return;
      }
      
      // Build Query Params
      List<String> queryParams = ["page=$page", "limit=$_limit"];
      if (_searchQuery.isNotEmpty) {
          queryParams.add("search=$_searchQuery");
      }
      if (_selectedStatus != 'ALL') {
          queryParams.add("status=$_selectedStatus");
      }
      
      final queryString = queryParams.join("&");
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/bills?$queryString");
      
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            // Handle if data is directly a list, or wrapped in an object { bills: [...] }
            final innerData = decoded['data'];
            if (innerData is List) {
                _bills = innerData;
            } else if (innerData is Map && innerData['bills'] is List) {
                _bills = innerData['bills'];
            } else if (innerData is Map && innerData['data'] is List) {
                // Sometime paginated responses wrap an extra data
                _bills = innerData['data'];
            } else {
                _bills = [];
            }
            
            _totalPages = decoded['totalPages'] ?? 1;
            
             // Hard page cap fallback
            if (page > _totalPages && _totalPages > 0) {
               _currentPage = _totalPages;
            } else {
               _currentPage = page;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = decoded['message'] ?? "No bills found";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = "Failed to load bills (Error ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Network Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
     if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
     // Wait a beat before slamming the API (Needs dart:async import)
     _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
           _searchQuery = value.trim();
        });
        _fetchBills(page: 1);
     });
  }

  void _onStatusChanged(String? newStatus) {
     if (newStatus == null) return;
     setState(() {
         _selectedStatus = newStatus;
     });
     _fetchBills(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Bills & Invoices"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
           // Filter Header
           Container(
             padding: const EdgeInsets.all(16),
             color: Colors.white,
             child: Column(
               children: [
                 TextField(
                   onChanged: _onSearchChanged,
                   decoration: InputDecoration(
                     hintText: "Search by Bill Number or Mobile...",
                     prefixIcon: const Icon(Icons.search),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                     contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0)
                   ),
                 ),
                 const SizedBox(height: 10),
                 Row(
                   children: [
                     const Text("Status Filter: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                     const SizedBox(width: 10),
                     Expanded(
                       child: DropdownButton<String>(
                         value: _selectedStatus,
                         isExpanded: true,
                         items: const [
                           DropdownMenuItem(value: 'ALL', child: Text("All")),
                           DropdownMenuItem(value: 'COMPLETED', child: Text("Completed")),
                           DropdownMenuItem(value: 'DRAFT', child: Text("Draft")),
                           DropdownMenuItem(value: 'CREDIT', child: Text("Credit")),
                           DropdownMenuItem(value: 'REFUNDED', child: Text("Refunded")),
                         ],
                         onChanged: _onStatusChanged,
                       ),
                     )
                   ],
                 )
               ],
             ),
           ),
           
           // List Body
           Expanded(
             child: _buildListContent()
           ),
           
           // Pagination footer
           if (_totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 && !_isLoading ? () => _fetchBills(page: _currentPage - 1) : null,
                    ),
                    Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages && !_isLoading ? () => _fetchBills(page: _currentPage + 1) : null,
                    ),
                  ],
                ),
              )
        ],
      )
    );
  }

  Widget _buildListContent() {
     if (_isLoading && _bills.isEmpty) {
        return const Center(child: CircularProgressIndicator());
     }
     
     if (_error.isNotEmpty && _bills.isEmpty) {
        return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
     }
     
     if (_bills.isEmpty) {
        return const Center(child: Text("No bills found matching your criteria."));
     }
     
     return ListView.separated(
        padding: const EdgeInsets.all(15),
        itemCount: _bills.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
            final bill = _bills[index];
            return _buildBillCard(bill);
        }
     );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
     final String billId = bill['_id'] ?? '';
     final String billNumber = bill['billNumber'] ?? 'Unknown';
     final String status = bill['status'] ?? 'UNKNOWN';
     
     // Customers could be nested or flattened depending on pagination response
     final customerData = bill['customer'] ?? bill['customerSnapshot'] ?? {};
     final String customerName = customerData['name'] ?? 'Unknown Customer';
     
     num total = 0;
     if (bill['grandTotal'] != null) {
         final pt = bill['grandTotal'];
         total = pt is num ? pt : num.tryParse(pt.toString()) ?? 0;
     }
     
     String dateString = bill['createdAt'] ?? '';
     try {
       if (dateString.isNotEmpty) {
          final dt = DateTime.parse(dateString);
          dateString = DateFormat('MMM d, yyyy').format(dt.toLocal());
       }
     } catch (_) {}

     Color statusColor = Colors.grey;
     if (status == 'COMPLETED') statusColor = Colors.green;
     if (status == 'DRAFT') statusColor = Colors.orange;
     if (status == 'REFUNDED') statusColor = Colors.red;
     if (status == 'CREDIT') statusColor = Colors.blue;

     return InkWell(
       onTap: () {
          if (billId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: billId))
              ).then((_) {
                 // Refresh lightly on pop back inside
                 _fetchBills(page: _currentPage);
              });
          }
       },
       child: Container(
         padding: const EdgeInsets.all(15),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade200)
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("#$billNumber", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 const SizedBox(height: 4),
                 Text(customerName, style: const TextStyle(color: Colors.black87)),
                 const SizedBox(height: 4),
                 Text(dateString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
               ],
             ),
             Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 const SizedBox(height: 5),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: statusColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: statusColor)
                   ),
                   child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                 )
               ],
             )
           ],
         ),
       ),
     );
  }
}
