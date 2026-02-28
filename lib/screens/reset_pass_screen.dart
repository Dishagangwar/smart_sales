import 'package:flutter/material.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

import 'package:flutter_animate/flutter_animate.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; 

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> handleResetPassword() async {
    final otp = otpController.text.trim();
    final newPassword = passwordController.text.trim();

    if (otp.length != 6) {
       _showSnackBar("Please enter the 6-digit OTP sent to your email.");
       return;
    }
    if (newPassword.length < 6) {
       _showSnackBar("New password must be at least 6 characters.");
       return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService().resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        await StorageService().clearStorage(); 
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text("Password reset successfully! Please login.", style: TextStyle(color: Colors.white)),
             backgroundColor: Colors.green,
          )
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showSnackBar(response['message'] ?? "Reset failed");
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 70, color: Theme.of(context).colorScheme.primary)
                      .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      
                  const SizedBox(height: 15),
                  
                  Text(
                    "Reset Password",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "Resetting for: ${widget.email}", 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 1. OTP Field
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.onetwothree),
                      labelText: "Enter 6-Digit OTP",
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 2. New Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                      labelText: "New Password",
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: handleResetPassword,
                          child: const Text("Reset Password"),
                        ),
                ],
              ).animate().fade(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOut),
            ),
          ),
        ),
      ),
    );
  }
}