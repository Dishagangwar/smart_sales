import 'package:flutter/material.dart';
import 'package:smart_sales/core/constants/role.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/features/auth/data/auth_service.dart';
import 'package:smart_sales/features/auth/data/models/login_request_model.dart';
import 'package:smart_sales/screens/super_admin_login.dart';
import 'forgot_pass_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role; // 👈 ENUM

  const LoginScreen({
    Key? key,
    this.role = UserRole.ADMIN, // 👈 default role
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _clearOldSession();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_controller);

    _controller.forward();
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
        loginAsRole: widget.role.value, // 👈 ENUM converted to String
      );

      final response = await AuthService().login(request);

      if (response != null && response['success'] == true) {
        // 1. Extract the NEW token for this Admin
        String token = response['data']['accessToken'];
        print("DEBUG ACCESS TOKEN: $token");
        await StorageService().saveToken(token);

        print("Logged in as Admin successfully!");

        // 3. Navigate to the Admin Dashboard
        String selectedRole = widget.role.value;
        await StorageService().saveRole(selectedRole);

        print("Logged in successfully as $selectedRole");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Error: $e")));
    }

    setState(() => isLoading = false);
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
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
                  margin: EdgeInsets.symmetric(horizontal: 25),
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 15),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 70, color: Color(0xFF1565C0)),

                      SizedBox(height: 15),

                      Text(
                        "Smart Sales",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),

                      SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: "Email / Admin ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          child: Text("Forgot Password?"),
                        ),
                      ),

                      SizedBox(height: 10),

                      isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1565C0),
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: loginUser,
                              child: Text("Login"),
                            ),

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
                        child: Text("Login as Super Admin"),
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
