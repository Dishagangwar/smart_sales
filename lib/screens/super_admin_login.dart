import 'package:flutter/material.dart';
import 'package:smart_sales/core/constants/role.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/features/auth/data/models/login_request_model.dart';
import 'package:smart_sales/screens/forgot_pass_screen.dart';
import 'package:smart_sales/screens/home_screen.dart';
import 'package:smart_sales/screens/super_admin_dashboard.dart';

import 'package:flutter_animate/flutter_animate.dart';

class SuperAdminLogin extends StatefulWidget {
  final UserRole role;

  const SuperAdminLogin({
    Key? key,
    this.role = UserRole.SUPER_ADMIN,
  }) : super(key: key);

  @override
  State<SuperAdminLogin> createState() => _SuperAdminLoginState();
}

class _SuperAdminLoginState extends State<SuperAdminLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _storage = StorageService();

  bool isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _storage.clearStorage();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await _storage.getSavedCredentials();
    if (credentials != null) {
      if (mounted) {
        setState(() {
          emailController.text = credentials['email']!;
          passwordController.text = credentials['password']!;
          _rememberMe = true;
        });
      }
    }
  }

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showError("Please enter both email and password");
      return;
    }

    setState(() => isLoading = true);

    try {
      final request = LoginRequestModel(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
        loginAsRole: UserRole.SUPER_ADMIN.value,
      );

      final response = await AuthService().login(request);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final String? token = data != null ? data['accessToken'] : null;

        if (token != null) {
          await _storage.saveToken(token);
          await _storage.saveRole("SUPER_ADMIN");

          if (_rememberMe) {
            await _storage.saveCredentials(emailController.text.trim(), passwordController.text.trim());
          } else {
            await _storage.deleteCredentials();
          }

          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
          }
        } else {
          showError("Login successful but token not found");
        }
      } else {
        showError(response?['message'] ?? "Invalid credentials");
      }
    } catch (e) {
      showError("Connection Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
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
                  Icon(Icons.security, size: 70, color: Theme.of(context).colorScheme.primary)
                      .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      
                  const SizedBox(height: 15),
                  
                  Text(
                    "Super Admin Login",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                      
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Super Admin Email",
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
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text("Remember Me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: loginUser,
                          child: const Text("Login"),
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