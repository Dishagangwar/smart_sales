import 'package:flutter/material.dart';

class NewBillStep1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomBar(context, "NEXT STEP →", "/bill2"),
      body: Column(
        children: [
          _header("New Bill", "Add a new Bill"),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Customer Details",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  SizedBox(height: 20),

                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.camera_alt,
                          size: 40, color: Colors.blue),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Mobile Number*",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Customer Name*",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Address (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget _header(String title, String subtitle) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40),
        Text(title,
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: TextStyle(color: Colors.white70)),
      ],
    ),
  );
}

Widget _bottomBar(BuildContext context, String text, String route) {
  return Padding(
    padding: EdgeInsets.all(15),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(text, style: TextStyle(fontSize: 16)),
    ),
  );
}