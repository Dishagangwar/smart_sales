import 'package:flutter/material.dart';
import 'create_admin_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: Color(0xFF1565C0),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(
                horizontal: 40, vertical: 15),
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
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}