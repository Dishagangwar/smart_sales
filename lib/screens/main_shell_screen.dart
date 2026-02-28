import 'package:flutter/material.dart';
import 'package:smart_sales/screens/customer_details_screen.dart'; // Tab 0: Bills 
import 'package:smart_sales/screens/customer_details_list.dart'; // Tab 1: Customers
import 'package:smart_sales/screens/home_screen.dart'; // We use Home as Tab 2 or as main
import 'package:smart_sales/screens/painter_list_screen.dart'; // Tab 3: Painters
import 'package:smart_sales/screens/report_screen.dart'; // Tab 4: Reports
import 'package:smart_sales/screens/create_category_screen.dart';
import 'package:smart_sales/screens/create_product_screen.dart'; 
import 'package:smart_sales/screens/product_list_screen.dart';
import 'package:smart_sales/screens/category_list_screen.dart';
import 'package:smart_sales/screens/create_customer_screen.dart';
import 'package:smart_sales/screens/create_painter_screen.dart';
import 'package:smart_sales/screens/painter_payment_screen.dart';
import 'package:smart_sales/screens/Add_product_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
       // Pop to first route if tapping the same tab
       _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
       setState(() {
         _currentIndex = index;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_currentIndex != 0) {
            setState(() { _currentIndex = 0; });
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(0, HomeScreen()),
            _buildTabNavigator(1, const CustomerDetailsScreen()),
            _buildTabNavigator(2, NewBillStep1()),
            _buildTabNavigator(3, const PainterListScreen()),
            _buildTabNavigator(4, ReportsScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Customers"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "New Bill"),
            BottomNavigationBarItem(icon: Icon(Icons.format_paint), label: "Painters"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget rootWidget) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/createCustomer':
            page = CreateCustomerScreen();
            break;
          case '/createPainter':
            page = CreatePainterScreen();
            break;
          case '/createCategory':
            page = CreateCategoryScreen();
            break;
          case '/categoriesList':
            page = const CategoryListScreen();
            break;
          case '/createProduct':
            page = CreateProductScreen();
            break;
          case '/productsList':
            page = const ProductListScreen();
            break;
          case '/bill1':
            page = NewBillStep1();
            break;
          case '/bill2':
            page = NewBillStep2();
            break;
          case '/bill3':
            page = NewBillStep3();
            break;
          case '/customers':
            page = const CustomerDetailsScreen();
            break;
          case '/painters':
            page = const PainterListScreen();
            break;
          case '/reports':
            page = ReportsScreen();
            break;
          case '/home':
            // Instead of root home screen returning a new Shell, just return HomeScreen
            page = HomeScreen();
            break;
          default:
            page = rootWidget;
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
    );
  }
}
