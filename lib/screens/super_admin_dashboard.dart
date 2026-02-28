import 'package:flutter/material.dart';
import 'package:smart_sales/screens/admins_list_screen.dart';
import 'create_admin_screen.dart';
 // Ensure this matches your file name

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button 1: Create Admin
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAdminScreen(),
                  ),
                );
              },
              child: const Text(
                "Create Admin",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20), // Spacing between buttons

            // Button 2: Admin List (Management)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, // Distinct color for management
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminManagementScreen(), //
                  ),
                );
              },
              child: const Text(
                "View Admin List",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}