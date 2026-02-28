import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_sales/core/storage/storage_service.dart';

class BillDetailsScreen extends StatefulWidget {
  final String billId;

  const BillDetailsScreen({super.key, required this.billId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  Map<String, dynamic>? _bill;
  bool _isLoading = true;
  String _error = '';
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _userRole = await StorageService().getRole();
    await _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/bills/${widget.billId}");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() => _bill = decoded['data']);
        } else {
          setState(() => _error = decoded['message'] ?? "Failed to load bill");
        }
      } else {
        setState(() => _error = "Server Error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  void _showRefundDialog() {
    if (_bill == null) return;
    
    final TextEditingController amountController = TextEditingController();
    num maxRefund = _parseNum(_bill!['grandTotal']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Issue Refund", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Max allowable refund: ₹${maxRefund.toStringAsFixed(2)}"),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Refund Amount",
                border: OutlineInputBorder(),
                prefixText: "₹ "
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               final amount = double.tryParse(amountController.text.trim());
               if (amount == null || amount <= 0 || amount > maxRefund) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid refund amount")));
                  return;
               }
               Navigator.pop(context);
               _processRefund(amount);
            },
            child: const Text("Process Refund", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _processRefund(double amount) async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService().getToken();
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/bills/${widget.billId}/refund");
      final response = await http.post(
        url,
        headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
        },
        body: jsonEncode({"amount": amount})
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Refund Successful"), backgroundColor: Colors.green));
             _fetchBillDetails(); // Reload the bill UI
          }
      } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Refund Failed")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMarkPaidDialog() {
    if (_bill == null) return;
    
    final TextEditingController amountController = TextEditingController();
    num remainingBalance = _parseNum(_bill!['details']?['remainingBalance']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Record Payment for Credit", style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pending Balance: ₹${remainingBalance.toStringAsFixed(2)}"),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Payment Amount",
                border: OutlineInputBorder(),
                prefixText: "₹ "
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
               final amount = double.tryParse(amountController.text.trim());
               if (amount == null || amount <= 0 || amount > remainingBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid payment amount")));
                  return;
               }
               Navigator.pop(context);
               _processMarkPaid(amount);
            },
            child: const Text("Record Payment", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _processMarkPaid(double amount) async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService().getToken();
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/bills/${widget.billId}/mark-paid");
      final response = await http.post(
        url,
        headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
        },
        body: jsonEncode({"amount": amount})
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Payment Recorded"), backgroundColor: Colors.green));
             _fetchBillDetails(); // Reload the bill UI
          }
      } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Payment Failed")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTransactionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Bill Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _fetchTransactions(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                        }
                        final txs = snapshot.data ?? [];
                        if (txs.isEmpty) {
                          return const Center(child: Text("No transactions recorded for this bill."));
                        }
                        
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: txs.length,
                          separatorBuilder: (context, index) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                             final t = txs[index];
                             final type = t['entryType'] ?? 'UNKNOWN';
                             final amount = _parseNum(t['amount']);
                             
                             String dateStr = t['createdAt'] ?? '';
                             try {
                                if (dateStr.isNotEmpty) {
                                  dateStr = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(dateStr).toLocal());
                                }
                             } catch (_) {}
                             
                             return ListTile(
                               contentPadding: EdgeInsets.zero,
                               leading: CircleAvatar(
                                 backgroundColor: Colors.blueGrey.shade100,
                                 child: const Icon(Icons.receipt, color: Colors.blueGrey),
                               ),
                               title: Text(type.toString().replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold)),
                               subtitle: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   if (t['note'] != null && t['note'].toString().isNotEmpty)
                                      Text(t['note'].toString(), style: const TextStyle(fontStyle: FontStyle.italic)),
                                   Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                 ],
                               ),
                               trailing: Text(
                                 "${amount > 0 ? '+' : ''}₹${amount.toStringAsFixed(2)}",
                                 style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    color: amount > 0 ? Colors.green : Colors.red
                                 )
                               ),
                             );
                          },
                        );
                      }
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
  
  Future<List<dynamic>> _fetchTransactions() async {
      final token = await StorageService().getToken();
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/bills/${widget.billId}/transactions");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (decoded['success'] == true) {
             return decoded['data'] ?? [];
         }
      }
      throw Exception("Failed to load transactions.");
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Details"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)));
    if (_bill == null) return const Center(child: Text("Bill completely missing"));

    final String status = _bill!['status'] ?? 'UNKNOWN';
    final String paymentMode = _bill!['paymentMode'] ?? 'UNKNOWN';
    
    // Derived states
    final bool isCompleted = status == "COMPLETED";
    final bool isRefunded = status == "REFUNDED"; 
    final bool isCredit = paymentMode == "CREDIT";
    num remainingBalance = _parseNum(_bill!['details']?['remainingBalance']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 15),
          _buildItemsCard(),
          const SizedBox(height: 15),
          _buildTotalsCard(),
          
          const SizedBox(height: 20),
          
          // AUDIT TRANSACTIONS
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueGrey,
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _showTransactionsSheet,
            icon: const Icon(Icons.history),
            label: const Text("View Bill Transactions", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 30),
          
          // ACTIONS
          if (_userRole == "SUPER_ADMIN" && isCompleted) ...[
             ElevatedButton.icon(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red.shade50,
                 foregroundColor: Colors.red,
                 padding: const EdgeInsets.symmetric(vertical: 15),
                 side: BorderSide(color: Colors.red.shade200)
               ),
               onPressed: _showRefundDialog,
               icon: const Icon(Icons.keyboard_return),
               label: const Text("Refund Bill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             ),
             const SizedBox(height: 15),
          ],
          
          if (isCredit && remainingBalance > 0 && !isRefunded && status != "DRAFT") ...[
             ElevatedButton.icon(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.green,
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 15),
               ),
               onPressed: _showMarkPaidDialog,
               icon: const Icon(Icons.payments),
               label: const Text("Mark Credit Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             ),
             const SizedBox(height: 15),
          ]
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    String dateString = _bill!['createdAt'] ?? '';
    try {
      if (dateString.isNotEmpty) {
        final DateTime dt = DateTime.parse(dateString);
        dateString = DateFormat('MMM d, yyyy • h:mm a').format(dt);
      }
    } catch (_) {}

    Color statusColor = Colors.grey;
    if (_bill!['status'] == 'COMPLETED') statusColor = Colors.green;
    if (_bill!['status'] == 'DRAFT') statusColor = Colors.orange;
    if (_bill!['status'] == 'REFUNDED') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Invoice #${_bill!['billNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(_bill!['status'] ?? 'UNKNOWN', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dateString, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 30),
          
          if (_bill!['customerSnapshot'] != null)
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const Text("BILLED TO:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                       const SizedBox(width: 8),
                       Text("${_bill!['customerSnapshot']['name'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                       const SizedBox(width: 8),
                       Text("${_bill!['customerSnapshot']['mobile'] ?? 'No Mobile'}"),
                    ],
                  ),
               ],
             ),
             
          if (_bill!['painterSnapshot'] != null) ...[
             const SizedBox(height: 15),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const Text("CONTRACTOR LINKED:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       const Icon(Icons.format_paint, size: 16, color: Colors.indigo),
                       const SizedBox(width: 8),
                       // The API doesn't populate painter name in standard get, we only have painterId
                       // But often its prepopulated if populated in backend. For now just show "Linked"
                       Text(
                         _bill!['painterSnapshot']['painterName'] ?? "Contractor ID: ${_bill!['painterSnapshot']['painterId'].toString().substring(0,6)}...", 
                         style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
                       ),
                    ],
                  ),
               ]
             )
          ]
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    List<dynamic> items = _bill!['lineItems'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text("CART ITEMS", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
           const SizedBox(height: 10),
           if (items.isEmpty) const Text("No items in bill."),
           ...items.map((item) {
              num subtotal = _parseNum(item['quantity']) * _parseNum(item['sellingPrice']);
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item['name']} x ${item['quantity']}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text("₹${subtotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                ],
              );
           }).toList()
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    num subTotal = _parseNum(_bill!['details']?['subTotal']) ?? 0;
    num tax = _parseNum(_bill!['tax']);
    num discount = _parseNum(_bill!['discount']);
    num grandTotal = _parseNum(_bill!['grandTotal']);
    num paidAmount = _parseNum(_bill!['paidAmount']);
    num remaining = _parseNum(_bill!['details']?['remainingBalance']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sub Total"),
              Text("₹${subTotal.toStringAsFixed(2)}"),
            ],
          ),
          if (tax > 0) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tax"),
                Text("+ ₹${tax.toStringAsFixed(2)}"),
              ],
            ),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Discount"),
                Text("- ₹${discount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red)),
              ],
            ),
          ],
          const Divider(height: 20, thickness: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("GRAND TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹${grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            ],
          ),
          
          if (_bill!['status'] != 'DRAFT' && _bill!['status'] != 'REFUNDED') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bill!['paymentMode'] == 'CREDIT' ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Mode: ${_bill!['paymentMode'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Paid: ₹${paidAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                     ),
                     if (_bill!['paymentMode'] == 'CREDIT') ...[
                        const Divider(),
                         Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Pending:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text("₹${remaining.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                         ),
                     ]
                  ],
                ),
              )
          ]
        ],
      ),
    );
  }

  // Safe Num parser
  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }
}
