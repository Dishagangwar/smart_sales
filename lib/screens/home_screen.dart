import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/main.dart'; // To access routeObserver
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final StorageService _storageService = StorageService();
  String? userRole;

  // Added variables for stats
  int totalCategories = 0;
  int activeCategories = 0;
  int deletedCategories = 0;
  bool _isLoadingStats = false;

  // Added variables for customer stats
  int totalCustomers = 0;
  int activeCustomers = 0;
  int deletedCustomers = 0;
  bool _isLoadingCustomerStats = false;

  List<dynamic> _outstandingCustomers = [];
  bool _isLoadingOutstanding = false;

  List<dynamic> _topCustomers = [];
  bool _isLoadingTop = false;

  List<dynamic> _outstandingPainters = [];
  bool _isLoadingPainters = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchAllDashboardData();
  }

  void _fetchAllDashboardData() {
    _fetchCategoryStats();
    _fetchCustomerStats();
    _fetchOutstandingCustomers();
    _fetchTopCustomers();
    _fetchOutstandingPainters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when returning to this screen
  @override
  void didPopNext() {
    _fetchAllDashboardData();
  }

  // Helper method to fetch the role from Secure Storage
  Future<void> _loadUserRole() async {
    final role = await StorageService().getRole();
    setState(() {
      userRole = role;
    });
  }

  // Added method to fetch category stats
  Future<void> _fetchCategoryStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load Stale Cache Instantly
    final cachedData = prefs.getString('cache_category_stats');
    if (cachedData != null) {
       final data = jsonDecode(cachedData);
       if (mounted) {
         setState(() {
           totalCategories = data['total'] ?? 0;
           activeCategories = data['active'] ?? 0;
           deletedCategories = data['deleted'] ?? 0;
           _isLoadingStats = false;
         });
       }
    } else {
       if (mounted) setState(() => _isLoadingStats = true);
    }

    // 2. Fetch Fresh Data
    try {
      final token = await _storageService.getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/categories/stats/overview");
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
          final data = decoded['data'];
          await prefs.setString('cache_category_stats', jsonEncode(data)); // Save to Cache
          if (mounted) {
            setState(() {
              totalCategories = data['total'] ?? 0;
              activeCategories = data['active'] ?? 0;
              deletedCategories = data['deleted'] ?? 0;
              _isLoadingStats = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchCustomerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cache_customer_stats');
    
    if (cachedData != null) {
       final data = jsonDecode(cachedData);
       if (mounted) {
         setState(() {
           totalCustomers = data['total'] ?? 0;
           activeCustomers = data['active'] ?? 0;
           deletedCustomers = data['deleted'] ?? 0;
           _isLoadingCustomerStats = false;
         });
       }
    } else {
       if (mounted) setState(() => _isLoadingCustomerStats = true);
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/customers/stats/overview"), headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final data = decoded['data'];
          await prefs.setString('cache_customer_stats', jsonEncode(data));
          
          if (mounted) {
            setState(() {
              totalCustomers = data['total'] ?? 0;
              activeCustomers = data['active'] ?? 0;
              deletedCustomers = data['deleted'] ?? 0;
              _isLoadingCustomerStats = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingCustomerStats = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCustomerStats = false);
    }
  }

  Future<void> _fetchOutstandingCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cache_outstanding_customers');
    
    if (cachedData != null) {
       if (mounted) {
         setState(() {
           _outstandingCustomers = jsonDecode(cachedData);
           _isLoadingOutstanding = false;
         });
       }
    } else {
       if (mounted) setState(() => _isLoadingOutstanding = true);
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/customers/outstanding/list?page=1&limit=5"), headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final data = decoded['data'] ?? [];
          await prefs.setString('cache_outstanding_customers', jsonEncode(data));
          
          if (mounted) {
            setState(() {
              _outstandingCustomers = data;
              _isLoadingOutstanding = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingOutstanding = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOutstanding = false);
    }
  }

  Future<void> _fetchTopCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cache_top_customers');
    
    if (cachedData != null) {
       if (mounted) {
         setState(() {
           _topCustomers = jsonDecode(cachedData);
           _isLoadingTop = false;
         });
       }
    } else {
       if (mounted) setState(() => _isLoadingTop = true);
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/customers/top?limit=10"), headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final data = decoded['data'] ?? [];
          await prefs.setString('cache_top_customers', jsonEncode(data));
          
          if (mounted) {
            setState(() {
              _topCustomers = data;
              _isLoadingTop = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingTop = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTop = false);
    }
  }

  Future<void> _fetchOutstandingPainters() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cache_outstanding_painters');
    
    if (cachedData != null) {
       if (mounted) {
         setState(() {
           _outstandingPainters = jsonDecode(cachedData);
           _isLoadingPainters = false;
         });
       }
    } else {
       if (mounted) setState(() => _isLoadingPainters = true);
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/painters/reports/outstanding"), headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
           final data = decoded['data'] ?? [];
           await prefs.setString('cache_outstanding_painters', jsonEncode(data));
           
           if (mounted) {
             setState(() {
               _outstandingPainters = data;
               _isLoadingPainters = false;
             });
           }
        }
      } else {
        if (mounted) setState(() => _isLoadingPainters = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPainters = false);
    }
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          /// 🔵 HEADER
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  "Smart Sales",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Find customer bills and transactions",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// ✅ CENTERED GRID
          /// ✅ SCROLLABLE CENTERED GRID
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Category Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard("Total", totalCategories, Colors.blueAccent, Icons.assessment),
                        const SizedBox(width: 8),
                        _buildStatCard("Active", activeCategories, Colors.green, Icons.check_circle),
                        const SizedBox(width: 8),
                        _buildStatCard("Deleted", deletedCategories, Colors.redAccent, Icons.delete),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- CUSTOMER OVERVIEW ---
                    const Text(
                      "Customer Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard("Total", totalCustomers, Colors.deepPurple, Icons.group),
                        const SizedBox(width: 8),
                        _buildStatCard("Active", activeCustomers, Colors.teal, Icons.verified_user),
                        const SizedBox(width: 8),
                        _buildStatCard("Deleted", deletedCustomers, Colors.redAccent, Icons.person_off),
                      ],
                    ),
                      
                    const SizedBox(height: 25),

                    // --- OUTSTANDING CUSTOMERS ---
                    const Text(
                      "Priority Collections",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_outstandingCustomers.isEmpty)
                      const Text("No outstanding balances!", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic))
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _outstandingCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _outstandingCustomers[index];
                            final num balance = customer['currentBalance'] != null 
                              ? (customer['currentBalance'] is num ? customer['currentBalance'] : num.tryParse(customer['currentBalance'].toString()) ?? 0)
                              : 0;
                            return _buildCustomerMiniCard(
                              customer['name'] ?? "Unknown", 
                              customer['mobile'] ?? "", 
                              balance, 
                              Colors.red.shade50, 
                              Colors.red
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 25),

                    // --- TOP CUSTOMERS ---
                    const Text(
                      "Top Customers",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_topCustomers.isEmpty)
                      const Text("No top customers data yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _topCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _topCustomers[index];
                            final num sales = customer['totalLifetimeSales'] != null 
                              ? (customer['totalLifetimeSales'] is num ? customer['totalLifetimeSales'] : num.tryParse(customer['totalLifetimeSales'].toString()) ?? 0)
                              : 0;
                            return _buildCustomerMiniCard(
                              customer['name'] ?? "Unknown", 
                              "Sales: ₹${sales.toStringAsFixed(0)}", 
                              null, 
                              Colors.green.shade50, 
                              Colors.green.shade800
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 25),

                    // --- OUTSTANDING PAINTERS ---
                    const Text(
                      "Pending Painter Comms",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_outstandingPainters.isEmpty)
                      const Text("No pending painter commissions!", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic))
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _outstandingPainters.length,
                          itemBuilder: (context, index) {
                            final painter = _outstandingPainters[index];
                            final num balance = painter['currentBalance'] != null 
                              ? (painter['currentBalance'] is num ? painter['currentBalance'] : num.tryParse(painter['currentBalance'].toString()) ?? 0)
                              : 0;
                            return _buildCustomerMiniCard(
                              painter['name'] ?? "Unknown", 
                              painter['mobile'] ?? "", 
                              balance, 
                              Colors.indigo.shade50, 
                              Colors.indigo,
                              iconOverride: Icons.format_paint
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 25),
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Let SingleChildScrollView handle the scrolling
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                  ),
                  children: [
                    _homeCard(context, Icons.people, "Customers List", '/customerDetailsList'),
                    _homeCard(context, Icons.note_add, "New Bill", '/bill1'),
                    _homeCard(context, Icons.receipt_long, "All Bills", '/billsList'),
                    _homeCard(context, Icons.format_paint, "Painters", '/painters'),
                    _homeCard(context, Icons.bar_chart, "Reports", '/reports'),
                    _homeCard(context, Icons.category, "Category", '/categoriesList'),
                    _homeCard(context, Icons.inventory_2, "Add Product", '/createProduct'),
                    _homeCard(context, Icons.list_alt, "All Products", '/productsList'), 
                  ],
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeCard(
      BuildContext context, IconData icon, String title, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMiniCard(String name, String sub1, num? overrideAmount, Color bgColor, Color textColor, {IconData iconOverride = Icons.person}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: textColor.withOpacity(0.2),
            radius: 16,
            child: Icon(iconOverride, color: textColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (overrideAmount != null)
             Text("₹${overrideAmount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16))
          else
             Text(sub1, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}