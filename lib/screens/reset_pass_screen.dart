import 'package:flutter/material.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // Passed from ForgotPasswordScreen

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers for the new required fields
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  Future<void> handleResetPassword() async {
    setState(() => isLoading = true);

    try {
      // API requires email, otp, and newPassword
      final response = await AuthService().resetPassword(
        email: widget.email,
        otp: otpController.text.trim(),
        newPassword: passwordController.text.trim(),
      );

      if (response['success'] == true) {
        // Clear stored tokens and redirect to login on success
        await StorageService().clearStorage(); 
        _showSnackBar("Password reset successful!");
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showSnackBar(response['message'] ?? "Reset failed");
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, size: 70, color: Color(0xFF1565C0)),
                      const SizedBox(height: 15),
                      const Text(
                        "Reset Password",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(height: 10),
                      Text("Resetting for: ${widget.email}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 30),
                      
                      // 1. OTP Field
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.onetwothree),
                          labelText: "Enter 6-Digit OTP",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                          labelText: "New Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: handleResetPassword,
                              child: const Text("Reset Password", style: TextStyle(color: Colors.white)),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}