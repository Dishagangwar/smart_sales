import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/painter_profile_screen.dart';

class PainterListScreen extends StatefulWidget {
  const PainterListScreen({super.key});

  @override
  State<PainterListScreen> createState() => _PainterListScreenState();
}

class _PainterListScreenState extends State<PainterListScreen> {
  List<dynamic> _painters = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination & Search
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;
  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPainters();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPainters({int page = 1}) async {
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

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/painters?page=$page&limit=$_limit&search=$_searchQuery");
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
            _painters = decoded['data'] ?? [];
            _totalPages = decoded['totalPages'] ?? 1;
            if (_currentPage > _totalPages && _totalPages > 0) {
                _currentPage = _totalPages;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = decoded['message'] ?? "Failed to load painters";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error ${response.statusCode}: Failed to fetch painters";
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
        _fetchPainters(page: 1);
      }
    });
  }

  Future<void> _navigateAndRefresh(BuildContext context, String route) async {
    final result = await Navigator.pushNamed(context, route);
    if (result == true) {
      _fetchPainters(page: _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _navigateAndRefresh(context, '/createPainter'),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Create Painter",
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

                  const SizedBox(height: 15),

                  // --- List Content ---
                  Expanded(
                    child: _isLoading && _painters.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty && _painters.isEmpty
                            ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                            : _painters.isEmpty
                                ? const Center(child: Text("No painters found.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                                : ListView.builder(
                                    itemCount: _painters.length,
                                    itemBuilder: (context, index) {
                                      final painter = _painters[index];
                                      return _buildPainterCard(painter);
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
            onPressed: _currentPage > 1 && !_isLoading ? () => _fetchPainters(page: _currentPage - 1) : null,
          ),
          Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages && !_isLoading ? () => _fetchPainters(page: _currentPage + 1) : null,
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
        color: Colors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Contractors & Painters",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPainterCard(Map<String, dynamic> painter) {
    num balance = 0;
    if (painter['currentBalance'] != null) {
      final cb = painter['currentBalance'];
      balance = cb is num ? cb : num.tryParse(cb.toString()) ?? 0;
    }

    num commission = 0;
    if (painter['totalCommissionEarned'] != null) {
      final cm = painter['totalCommissionEarned'];
      commission = cm is num ? cm : num.tryParse(cm.toString()) ?? 0;
    }

    final bool hasDebt = balance > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PainterProfileScreen(painterData: painter))
        ).then((_) {
          if (mounted) _fetchPainters(page: _currentPage);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.shade50,
            radius: 24,
            child: const Icon(Icons.format_paint, color: Colors.indigo),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  painter['name'] ?? "Unknown",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  painter['mobile'] ?? "",
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hasDebt ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Text(
                  "Bal: ₹${balance.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  "Earned: ₹${commission.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 11
                  ),
                ),
              )
            ],
          )
        ],
      ),
      ),
    );
  }
}
