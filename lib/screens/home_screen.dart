import 'package:flutter/material.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;
  String? userRole;
  @override
  void initState() {
    super.initState();
    // 2. Load the role when the screen starts
    _loadUserRole();
  }

  // Helper method to fetch the role from Secure Storage
  Future<void> _loadUserRole() async {
    final role = await StorageService().getRole();
    setState(() {
      userRole = role;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/bill1');
        break;
      case 1:
        Navigator.pushNamed(context, '/customers');
        break;
      case 2:
        Navigator.pushNamed(context, '/search');
        break;
      case 3:
        Navigator.pushNamed(context, '/painters');
        break;
      case 4:
        Navigator.pushNamed(context, '/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Bills"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Customers"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.format_paint), label: "Painters"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
        ],
      ),

      body: Column(
        children: [

          /// 🔵 HEADER
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  "Smart Sales",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Find customer bills and transactions",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// ✅ CENTERED GRID
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                  ),
                  children: [
                    _homeCard(context, Icons.person, "Customer", '/customers'),
                    _homeCard(context, Icons.note_add, "New Bill", '/bill1'),
                    _homeCard(context, Icons.format_paint, "Painters", '/painters'),
                    _homeCard(context, Icons.bar_chart, "Reports", '/reports'),
                    _homeCard(context, Icons.category, "Category", '/createCategory'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeCard(
      BuildContext context, IconData icon, String title, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}