import 'package:flutter/material.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({Key? key}) : super(key: key);

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  // Required fields based on documentation
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  // Location Controllers - District and Postal Code are required by your backend
  final TextEditingController districtController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;

  void showCredentialsDialog(String username, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Admin Created Successfully"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please save these credentials. They will only be shown once:"),
            const SizedBox(height: 10),
            SelectableText("Username: $username", style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText("Password: $password", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Future<void> handleCreateAdmin() async {
    setState(() => isLoading = true);

    try {
      final storage = StorageService();
      String? token = await storage.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
        return;
      }

      final response = await AuthService().createAdmin(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: [phoneController.text.trim()], 
        location: {
          "state": "Uttar Pradesh", 
          "district": districtController.text.trim(), // Fixes the validation error
          "city": cityController.text.trim(),
          "postalCode": postalCodeController.text.trim(), // Added per doc requirement
          "address": addressController.text.trim(),
          "taluka": null, // Required keys from your doc
          "village": null,
        },
        token: token,
      );

      if (response.success && response.data != null) {
        showCredentialsDialog(response.data!.username, response.data!.password);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Admin"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(firstNameController, "First Name"),
            _buildTextField(lastNameController, "Last Name"),
            _buildTextField(emailController, "Email", keyboardType: TextInputType.emailAddress),
            _buildTextField(phoneController, "Phone Number", keyboardType: TextInputType.phone),
            _buildTextField(districtController, "District"), // New field
            _buildTextField(cityController, "City"),
            _buildTextField(postalCodeController, "Postal Code", keyboardType: TextInputType.number), // New field
            _buildTextField(addressController, "Full Address"),
            
            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: handleCreateAdmin,
                      child: const Text("Create Admin", style: TextStyle(color: Colors.white)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}