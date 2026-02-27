import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Reports"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            _reportCard(
              title: "Total Sales",
              amount: "₹ 4,25,000",
              subtitle: "142 Bills Generated",
              icon: Icons.trending_up,
            ),

            SizedBox(height: 16),

            _reportCard(
              title: "Painter Commission",
              amount: "₹ 42,500",
              subtitle: "Paid: ₹19k | Pending: ₹23.5k",
              icon: Icons.brush,
            ),

            SizedBox(height: 16),

            _reportCard(
              title: "Outstanding Credit",
              amount: "₹ 1,12,000",
              subtitle: "18 Customers Pending",
              icon: Icons.warning_amber_rounded,
            ),

            SizedBox(height: 16),

            _reportCard(
              title: "Category Sales",
              amount: "Interior & Exterior",
              subtitle: "View detailed breakdown",
              icon: Icons.pie_chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(height: 5),
                Text(amount,
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}