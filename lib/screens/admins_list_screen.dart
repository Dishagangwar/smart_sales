import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';
import 'dart:convert';

import 'package:smart_sales/screens/create_admin_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  int currentPage = 1;
  int totalPages = 1;
  List<dynamic> admins = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAdmins(currentPage);
  }

Future<void> fetchAdmins(int page) async {
  setState(() => isLoading = true);
  
  try {
    final storage = StorageService();
    final token = await storage.getToken();

    final response = await http.get(
      Uri.parse("https://chamanmarblel.onrender.com/api/users?page=$page&limit=10"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final responseData = jsonDecode(response.body);
    print("API RESPONSE LOG: $responseData"); // DEBUG PRINT THIS LINE

    if (response.statusCode == 200 && responseData['success'] == true) {
      setState(() {
        // Ensure data is not null by providing an empty list fallback
        admins = responseData['data'] ?? []; 
        
        // Convert to int safely to prevent parsing issues
        var apiPage = responseData['page'] ?? responseData['currentPage'] ?? 1;
        var apiTotalPages = responseData['totalPages'] ?? 1;
        
        currentPage = int.tryParse(apiPage.toString()) ?? 1;
        totalPages = int.tryParse(apiTotalPages.toString()) ?? 1;
        
        isLoading = false;
      });
    } else {
      setState(() {
        admins = []; // Handle empty list gracefully as per contract
        isLoading = false;
      });
    }
  } catch (e) {
    print("Error: $e");
    setState(() => isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management"),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAdminScreen(),
                  ),
                );
            }, // Navigate to Add Admin form
            icon: const Icon(Icons.add),
            label: const Text("ADD ADMIN"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          const ListTile(
            title: Text("System Administrators", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ROLE MANAGEMENT"),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : admins.isEmpty 
                ? const Center(child: Text("No admins found")) // Handle empty list gracefully
                : ListView.builder(
                    itemCount: admins.length,
                    itemBuilder: (context, index) => _buildAdminTile(admins[index]),
                  ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildAdminTile(dynamic admin) {
    if (admin == null || admin is! Map) {
      return const SizedBox.shrink();
    }

    final String name = (admin['name'] is List ? admin['name'].join(' ') : admin['name']?.toString()) ?? 'Unknown Admin';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final String email = (admin['email'] is List ? admin['email'].join(', ') : admin['email']?.toString()) ?? 'No email provided';
    final String phone = (admin['phone'] is List ? admin['phone'].join(', ') : admin['phone']?.toString()) ?? 'No phone provided';
    final String id = admin['_id']?.toString() ?? admin['id']?.toString() ?? "N/A";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(child: Text(initial)),
        title: Text(name),
        subtitle: Text("$email\n$phone"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(label: Text(id), backgroundColor: Colors.grey[200]),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: currentPage > 1 ? () => fetchAdmins(currentPage - 1) : null,
            child: const Text("PREVIOUS"),
          ),
          Text("PAGE $currentPage / $totalPages"), // Pagination UI
          TextButton(
            onPressed: currentPage < totalPages ? () => fetchAdmins(currentPage + 1) : null,
            child: const Text("NEXT"),
          ),
        ],
      ),
    );
  }
}