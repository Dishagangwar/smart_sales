import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/create_category_screen.dart';
import 'package:smart_sales/screens/edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  // Navigation / Pagination State
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  // Filter State
  String _searchQuery = "";
  String? _selectedType;
  bool _showDeleted = false;

  // Debounce Timer
  Timer? _debounce;

  // Constants
  final List<String> _categoryTypes = ["paint", "hardware", "sanitary", "marbles", "stationary", "others"];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- API Functions ---
  
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "No auth token. Please login.";
          _isLoading = false;
        });
        return;
      }

      // Build Query String
      // e.g. /api/categories?page=1&limit=20&search=pa&type=paint&isDeleted=false
      String url = "https://chamanmarblel.onrender.com/api/categories?page=$_currentPage&limit=$_limit&isDeleted=$_showDeleted";
      
      if (_searchQuery.isNotEmpty) {
        url += "&search=${Uri.encodeComponent(_searchQuery)}";
      }
      if (_selectedType != null && _selectedType!.isNotEmpty) {
        url += "&type=$_selectedType";
      }

      print("DEBUG CAT GET: \$url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("DEBUG CAT RES: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _categories = decoded['data'] ?? [];
            _totalPages = decoded['totalPages'] ?? 1;
            // safeguard to ensure current page resets if data is less than expected
            if (_currentPage > _totalPages && _totalPages > 0) {
                _currentPage = _totalPages;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'API failed: ${decoded['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to fetch';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
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
        Uri.parse("https://chamanmarblel.onrender.com/api/categories/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      
      final decoded = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category deleted successfully")));
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to delete category")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreCategory(String id) async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService().getToken();
      final response = await http.patch(
        Uri.parse("https://chamanmarblel.onrender.com/api/categories/$id/restore"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category restored successfully")));
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to restore category")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1; // Reset to page 1 on new search
        });
        _fetchCategories();
      }
    });
  }

  // --- Header Action Widgets ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search categories...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Category Type Dropdown Filter
          Expanded(
            child: DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  hint: const Text("All Types"),
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text("All Types")), // Reset option
                    ..._categoryTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                      _currentPage = 1;
                    });
                    _fetchCategories();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 ? () {
              setState(() => _currentPage--);
              _fetchCategories();
            } : null,
            child: const Text("Prev"),
          ),
          Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _currentPage < _totalPages ? () {
              setState(() => _currentPage++);
              _fetchCategories();
            } : null,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // --- Main List Widget ---

  Widget _buildList() {
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
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchCategories, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
       return const Center(
        child: Text("No categories found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final id = cat['_id'] ?? '';
        final name = cat['name'] ?? 'Unknown';
        final type = cat['type'] ?? 'N/A';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _showDeleted ? Colors.red.shade100 : Colors.blue.shade100,
              child: Icon(Icons.category, color: _showDeleted ? Colors.red : Colors.blue),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: $id\nType: $type"),
            isThreeLine: true,
            trailing: _showDeleted ? 
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.blue),
                onPressed: () => _restoreCategory(cat['_id']),
                tooltip: "Restore Category",
              ) : 
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditCategoryScreen(categoryData: cat)),
                    );
                    if (result == true) _fetchCategories();
                  } else if (value == 'delete') {
                    _deleteCategory(cat['_id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                ],
              ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Management"),
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
                    _currentPage = 1;
                  });
                  _fetchCategories();
                },
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Container(
             color: Colors.white,
             padding: const EdgeInsets.only(bottom: 10),
             child: Column(
               children: [
                 _buildSearchBar(),
                 _buildFilters(),
               ],
             ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList()),
          if (!_isLoading && _categories.isNotEmpty) _buildPaginationFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Push Create Category. If returned true/success, refresh list
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCategoryScreen()),
          );
          _fetchCategories();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
