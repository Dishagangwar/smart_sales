import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:smart_sales/common_widgets.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

class NewBillStep3 extends StatefulWidget {
  @override
  State<NewBillStep3> createState() => _NewBillStep3State();
}

class _NewBillStep3State extends State<NewBillStep3> {

  String paymentMode = "Cash";
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isSaving = false;

  Future<void> _saveBill(Map<String, dynamic>? args) async {
    if (args == null || args['billId'] == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Critical Error: Missing Draft Bill ID")));
       return;
    }

    setState(() => _isSaving = true);
    
    try {
       final token = await StorageService().getToken();
       if (token == null) throw Exception("No authentication token found");

       final billId = args['billId'];
       final advanceAmount = double.tryParse(_advanceController.text.trim()) ?? 0;
       
       // Construct identical payload to API contract Phase 2
       final Map<String, dynamic> payload = {
         "paymentMode": paymentMode.toUpperCase(), // "CASH" or "CREDIT"
         "paidAmount": advanceAmount,
         "notes": _notesController.text.trim(),
       };

       
       final response = await http.post(
         Uri.parse("https://chamanmarblel.onrender.com/api/bills/${billId.toString()}/complete"),
         headers: {
           "Content-Type": "application/json",
           "Authorization": "Bearer $token",
         },
         body: jsonEncode(payload),
       );

       print("COMPLETE BILL RESPONSE: ${response.statusCode} - ${response.body}");

       if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (decoded['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill Completed & Saved Successfully!"), backgroundColor: Colors.green));
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
         } else {
            throw Exception(decoded['message'] ?? "Unknown API Error");
         }
       } else {
          throw Exception("Server Error ${response.statusCode}: ${response.body}");
       }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to Complete Bill: $e")));
       }
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _advanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : () => _saveBill(args),
          child: _isSaving 
             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
             : const Text("SAVE BILL", style: TextStyle(fontSize: 16)),
        ),
      ),
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

                  if (args != null && args['painterId'] != null) ...[
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.indigo.shade100)),
                       child: Row(
                         children: const [
                           Icon(Icons.format_paint, color: Colors.indigo, size: 20),
                           SizedBox(width: 8),
                           Text("Painter is Linked to this Bill", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
                         ],
                       ),
                     ),
                     const SizedBox(height: 20),
                  ],

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

                  TextField(
                    controller: _advanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Advance Given by Customer",
                      border: OutlineInputBorder(),
                      prefixText: "₹ "
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
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