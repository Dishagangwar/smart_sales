import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:smart_sales/screens/bill_details_screen.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerLedgerScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  // Summary Data
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = true;
  String _summaryError = '';

  // Ledger List Data
  List<dynamic> _ledgerEntries = [];
  bool _isLoadingLedger = true;
  String _ledgerError = '';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchLedgerEntries();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final token = await StorageService().getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}/ledger/summary");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() => _summaryData = decoded['data']);
        } else {
          setState(() => _summaryError = decoded['message'] ?? "Summary failed");
        }
      } else {
        setState(() => _summaryError = "Error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _summaryError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _fetchLedgerEntries({int page = 1}) async {
    setState(() {
      _isLoadingLedger = true;
      _ledgerError = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) return;

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/${widget.customerId}/ledger?page=$page&limit=20");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _ledgerEntries = decoded['data'] ?? [];
            _currentPage = decoded['page'] ?? 1;
            _totalPages = decoded['totalPages'] ?? 1;
          });
        } else {
          setState(() => _ledgerError = decoded['message'] ?? "Ledger failed");
        }
      } else {
        setState(() => _ledgerError = "Error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _ledgerError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingLedger = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.customerName}'s Ledger"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildSummarySection(),
          const SizedBox(height: 10),
          Expanded(child: _buildLedgerListSection()),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_isLoadingSummary) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    if (_summaryError.isNotEmpty) return Padding(padding: const EdgeInsets.all(20), child: Text("Stats Error: $_summaryError", style: const TextStyle(color: Colors.red)));
    if (_summaryData == null) return const SizedBox.shrink();

    // Parse safely
    final num balance = _parseNum(_summaryData!['balance']);
    final num totalCredits = _parseNum(_summaryData!['totalCredits']);
    final num totalDebits = _parseNum(_summaryData!['totalDebits']);

    // Color code per spec: positive balance (owe us) is Red. Negative balance (we owe them / paid advance) is Green.
    final bool owesMoney = balance > 0;
    final MaterialColor balanceColor = owesMoney ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          const Text("TOTAL OUTSTANDING", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            "₹${balance.abs().toStringAsFixed(2)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: balanceColor),
          ),
          Text(
            owesMoney ? "Customer owes you" : (balance == 0 ? "Settled" : "You owe customer (Advance)"),
            style: TextStyle(fontSize: 12, color: balanceColor.shade300, fontWeight: FontWeight.bold),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text("Total Credits", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("₹${totalCredits.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Column(
                children: [
                  const Text("Total Debits", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("₹${totalDebits.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLedgerListSection() {
    if (_isLoadingLedger) return const Center(child: CircularProgressIndicator());
    if (_ledgerError.isNotEmpty) return Center(child: Text("Error: $_ledgerError", style: const TextStyle(color: Colors.red)));
    if (_ledgerEntries.isEmpty) return const Center(child: Text("Ledger is empty", style: TextStyle(color: Colors.grey)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text("Transaction History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _ledgerEntries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = _ledgerEntries[index];
              final type = entry['entryType'] ?? 'UNKNOWN';
              final num amount = _parseNum(entry['amount']);
              
              // Formatting Date
              String dateString = entry['createdAt'] ?? '';
              try {
                if (dateString.isNotEmpty) {
                  final DateTime dt = DateTime.parse(dateString);
                  dateString = DateFormat('MMM d, yyyy • h:mm a').format(dt);
                }
              } catch (_) {}

              // Frontend Rule: Positive -> Red (Owes), Negative -> Green (Paid)
              final bool isPositive = amount > 0;
              final Color amountColor = isPositive ? Colors.red : Colors.green.shade700;
              final String sign = isPositive ? "+" : ""; // Negative numbers already have "-"
              
              // Icon Selection based on entry type
              IconData icon;
              Color iconBgColor;
              if (type == 'BILL') {
                icon = Icons.receipt_long;
                iconBgColor = Colors.red.shade50;
              } else if (type == 'PAYMENT') {
                icon = Icons.payments;
                iconBgColor = Colors.green.shade50;
              } else if (type == 'REFUND') {
                icon = Icons.keyboard_return;
                iconBgColor = Colors.orange.shade50;
              } else {
                icon = Icons.compare_arrows;
                iconBgColor = Colors.grey.shade200;
              }

              // Safely extract the reference ID. Sometimes it's called refId, sometimes billId.
              // If it's a populated object (MongoDB), extract the _id.
              dynamic rawRef = entry['refId'] ?? entry['billId'];
              String? finalBillId;
              if (rawRef is Map) {
                finalBillId = rawRef['_id']?.toString();
              } else if (rawRef != null) {
                finalBillId = rawRef.toString();
              }

              return Container(
                color: Colors.white,
                child: InkWell(
                  onTap: (type == 'BILL' && finalBillId != null) ? () {
                     print("Tapped BILL Entry. Final ID resolved to: $finalBillId. Raw Ledger Entry: $entry");
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: finalBillId!))
                     );
                  } : (type == 'BILL' ? () {
                     print("Tapped BILL Entry but could not resolve ID! Raw Entry: $entry");
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot load bill details: Missing ID")));
                  } : null),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(backgroundColor: iconBgColor, child: Icon(icon, color: amountColor)),
                    title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(dateString, style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$sign₹${amount.toStringAsFixed(2)}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
                        ),
                        if (type == 'BILL') const Icon(Icons.chevron_right, color: Colors.grey)
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Paginator Tool
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: _currentPage > 1 && !_isLoadingLedger ? () => _fetchLedgerEntries(page: _currentPage - 1) : null,
                ),
                Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _currentPage < _totalPages && !_isLoadingLedger ? () => _fetchLedgerEntries(page: _currentPage + 1) : null,
                ),
              ],
            ),
          )
      ],
    );
  }

  // Safe Num parser
  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }
}
