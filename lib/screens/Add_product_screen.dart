import 'package:flutter/material.dart';
import 'package:smart_sales/common_widgets.dart';

class NewBillStep2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
         buildBottomButton(context, "PROCEED TO PAYMENT", "/bill3"),
      body: Column(
        children: [
         buildHeader("New Bill", "Add a new Bill"),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Add Product",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.add, color: Colors.blue)
                    ],
                  ),

                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Royal luxury (20L) x 1"),
                        Text("₹12,500"),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Royal luxury (20L) x 1"),
                        Text("₹12,500"),
                      ],
                    ),
                  ),

                  Spacer(),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("₹25,000",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}