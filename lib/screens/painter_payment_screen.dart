import 'package:flutter/material.dart';
import 'package:smart_sales/common_widgets.dart';

class NewBillStep3 extends StatefulWidget {
  @override
  State<NewBillStep3> createState() => _NewBillStep3State();
}

class _NewBillStep3State extends State<NewBillStep3> {

  String paymentMode = "Cash";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
         buildBottomButton(context, "SAVE BILL", "/home"),
      body: Column(
        children: [
          buildHeader("New Bill", "Add a new Bill"),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Painter & Payment",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),

                  SizedBox(height: 20),

                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: "Link Painter",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          child: Text("Suresh M."),
                          value: "Suresh"),
                    ],
                    onChanged: (value) {},
                  ),

                  SizedBox(height: 20),

                  Text("Payment Mode",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _paymentButton("Cash"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _paymentButton("Credit"),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Advance Given",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Notes",
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

  Widget _paymentButton(String type) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            paymentMode == type ? Colors.blue : Colors.grey.shade300,
      ),
      onPressed: () {
        setState(() {
          paymentMode = type;
        });
      },
      child: Text(type,
          style: TextStyle(
              color: paymentMode == type
                  ? Colors.white
                  : Colors.black)),
    );
  }
}