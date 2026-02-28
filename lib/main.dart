import 'package:flutter/material.dart';
import 'package:smart_sales/screens/Add_product_screen.dart';
import 'package:smart_sales/screens/bills_list_screen.dart';
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
import 'package:smart_sales/screens/create_product_screen.dart'; // Added Import
import 'package:smart_sales/screens/product_list_screen.dart';
import 'package:smart_sales/screens/category_list_screen.dart';
import 'package:smart_sales/screens/create_customer_screen.dart'; // New Customer Import
import 'package:smart_sales/screens/create_painter_screen.dart'; // New Painter Routes
import 'package:smart_sales/screens/painter_list_screen.dart';
import 'package:smart_sales/screens/main_shell_screen.dart';

import 'package:smart_sales/theme.dart';

// Global RouteObserver to detect when screens pop back to home
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(SmartSalesApp());
}

class SmartSalesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Sales",
      theme: AppTheme.lightTheme,
      navigatorObservers: [routeObserver], // Register global observer
      home: LoginScreen(),
      routes: {
        '/superAdmin': (context) => SuperAdminLogin(),
        '/forgot': (context) => ForgotPasswordScreen(), 
        // '/reset': (context) => ResetPasswordScreen(),
        '/home': (context) => const MainShellScreen(),
        '/customers': (context) => CustomerDetailsScreen(),
        '/customerDetailsList': (context) => const CustomerDetailsScreen(),
        '/bill1': (context) => NewBillStep1(),
        '/bill2': (context) => NewBillStep2(),
        '/bill3': (context) => NewBillStep3(),
        '/billsList': (context) => const BillsListScreen(),
        '/reports': (context) => ReportsScreen(),
        '/painters': (context) => const PainterListScreen(), // Replaced placeholder
        '/createPainter': (context) => CreatePainterScreen(), // New route
        '/createCustomer': (context) => CreateCustomerScreen(), // Added route
        '/createCategory': (context) => CreateCategoryScreen(),
        '/categoriesList': (context) => const CategoryListScreen(),
        '/createProduct': (context) =>  CreateProductScreen(), // New Route Added
        '/productsList': (context) => const ProductListScreen(), // Added Products List Route
      },
    );
  }
}
