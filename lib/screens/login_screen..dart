import 'package:flutter/material.dart';
import 'package:smart_sales/core/constants/role.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/features/auth/data/models/login_request_model.dart';
import 'package:smart_sales/screens/super_admin_login.dart';
import 'forgot_pass_screen.dart';

import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({
    Key? key,
    this.role = UserRole.ADMIN,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _clearOldSession();
  }

  Future<void> _clearOldSession() async {
    await StorageService().clearStorage();
    print("Purana session clear ho gaya hai.");
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    try {
      final request = LoginRequestModel(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
        loginAsRole: widget.role.value,
      );

      final response = await AuthService().login(request);

      if (response != null && response['success'] == true) {
        String token = response['data']['accessToken'];
        print("DEBUG ACCESS TOKEN: $token");
        await StorageService().saveToken(token);

        print("Logged in as Admin successfully!");

        String selectedRole = widget.role.value;
        await StorageService().saveRole(selectedRole);

        print("Logged in successfully as $selectedRole");
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Optional: We can keep the gradient or rely on the Theme Scaffold color. Let's keep the premium gradient back.
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
                  Icon(Icons.bar_chart, size: 70, color: Theme.of(context).colorScheme.primary)
                      .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 15),
                  
                  Text(
                    "Smart Sales",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Email / Admin ID",
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Password",
                    ),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: loginUser,
                          child: const Text("Login"),
                        ),
                  
                  const SizedBox(height: 15),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminLogin(
                            role: UserRole.SUPER_ADMIN,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Login as Super Admin", 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)
                    ),
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
