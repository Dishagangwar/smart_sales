import 'package:flutter/material.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/screens/reset_pass_screen.dart';

import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> handleForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
        _showError("Please enter your email address.");
        return;
    }
    
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) {
        _showError("Please enter a valid email address.");
        return;
    }

    setState(() => isLoading = true);
    try {
      final response = await AuthService().forgotPassword(email);

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent! It will expire in 10 minutes.", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          )
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email),
          ),
        );
      } else {
        _showError(response['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset, size: 70, color: Theme.of(context).colorScheme.primary)
                      .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      
                  const SizedBox(height: 15),
                  
                  Text(
                    "Forgot Password",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "Enter your email to receive an OTP",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Email",
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: handleForgotPassword,
                          child: const Text("Send OTP"),
                        ),
                        
                  const SizedBox(height: 15),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Back to Login", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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