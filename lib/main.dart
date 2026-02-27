import 'package:flutter/material.dart';
import 'package:smart_sales/screens/Add_product_screen.dart';
import 'package:smart_sales/screens/create_category_screen.dart';
import 'package:smart_sales/screens/customer_details_list.dart';
import 'package:smart_sales/screens/customer_details_screen.dart';
import 'package:smart_sales/screens/forgot_pass_screen.dart';
import 'package:smart_sales/screens/home_screen.dart';
import 'package:smart_sales/screens/login_screen..dart';
import 'package:smart_sales/screens/painter_payment_screen.dart';
import 'package:smart_sales/screens/painter_screen.dart';
import 'package:smart_sales/screens/report_screen.dart';
import 'package:smart_sales/screens/super_admin_login.dart';

void main() {
  runApp(SmartSalesApp());
}

class SmartSalesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Sales",
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/superAdmin': (context) => SuperAdminLogin(),
        '/forgot': (context) => ForgotPasswordScreen(),
        // '/reset': (context) => ResetPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/customers': (context) => CustomerDetailsScreen(),
        '/bill1': (context) => NewBillStep1(),
        '/bill2': (context) => NewBillStep2(),
        '/bill3': (context) => NewBillStep3(),
        '/reports': (context) => ReportsScreen(),
        '/painters': (context) => PaintersScreen(),
        '/createCategory': (context) => CreateCategoryScreen(),
      },
    );
  }
}
