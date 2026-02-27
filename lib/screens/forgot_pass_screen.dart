import 'package:flutter/material.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/screens/reset_pass_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  // logic to handle sending OTP via API and navigating immediately
  Future<void> handleForgotPassword() async {
    if (emailController.text.isEmpty) return;

    setState(() => isLoading = true);
    try {
      // POST /api/auth/forgot-password
      final response = await AuthService().forgotPassword(emailController.text.trim());

      if (response['success'] == true) {
        // - Frontend Flow requirement to show OTP input screen
        // Instead of a dialog, we navigate directly to the Reset screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: emailController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(response['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
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
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 15)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_reset, size: 70, color: Color(0xFF1565C0)),
                      const SizedBox(height: 15),
                      const Text(
                        "Forgot Password",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Enter your email to receive an OTP",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          labelText: "Email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: handleForgotPassword,
                              child: const Text("Send OTP", style: TextStyle(color: Colors.white)),
                            ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back to Login"),
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