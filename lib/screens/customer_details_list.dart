import 'package:flutter/material.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> bills = [
    {
      "id": "#BILL-8921",
      "name": "Rajesh Kumar",
      "painter": "Suresh M.",
      "amount": "₹12,500",
      "status": "PAID"
    },
    {
      "id": "#BILL-8920",
      "name": "Amit Contractors",
      "painter": "Self",
      "amount": "₹42,800",
      "status": "CREDIT"
    },
    {
      "id": "#BILL-8919",
      "name": "Priya Singh",
      "painter": "Vijay Colors",
      "amount": "₹3,570",
      "status": "PAID"
    },
    {
      "id": "#BILL-8918",
      "name": "Modern Villa",
      "painter": "Vipin Kumar",
      "amount": "₹1,600",
      "status": "PAID"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
          _header(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 🔍 Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search),
                        hintText: "Search for services....",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 📋 Bill List
                  Expanded(
                    child: ListView.builder(
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return _billCard(bill);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔵 Header
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Customer Details",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 📄 Bill Card UI
  Widget _billCard(Map<String, dynamic> bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Bill ID + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bill["id"],
                style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                bill["amount"],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Name
          Text(
            bill["name"],
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          /// Painter + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Painter: ${bill["painter"]}",
                style: const TextStyle(color: Colors.grey),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bill["status"] == "PAID"
                      ? Colors.blue
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bill["status"],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}