import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/bill_details_screen.dart';

class PainterLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> painterData;

  const PainterLedgerScreen({super.key, required this.painterData});

  @override
  State<PainterLedgerScreen> createState() => _PainterLedgerScreenState();
}

class _PainterLedgerScreenState extends State<PainterLedgerScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  Future<void> _fetchLedger({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication required";
          _isLoading = false;
        });
        return;
      }
      
      final painterId = widget.painterData['_id'];
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/painters/$painterId/ledger?page=$page&limit=$_limit");
      
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _transactions = decoded['data'] ?? [];
            _totalPages = decoded['totalPages'] ?? 1;
            if (page > _totalPages && _totalPages > 0) {
               _currentPage = _totalPages;
            } else {
               _currentPage = page;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = decoded['message'] ?? "No ledger records found";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load transactions (Error ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Network Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.painterData['name']} LEDGER".toUpperCase()),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
             if (_isLoading && _transactions.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
             else if (_errorMessage.isNotEmpty && _transactions.isEmpty)
                Expanded(child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))))
             else if (_transactions.isEmpty)
                const Expanded(child: Center(child: Text("No transactions recorded.", style: TextStyle(color: Colors.grey, fontSize: 16))))
             else ...[
                // Ledger List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                       final t = _transactions[index];
                       return _buildTransactionCard(t);
                    },
                  ),
                ),
                
                // Pagination Footer
                if (_totalPages > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1 && !_isLoading ? () => _fetchLedger(page: _currentPage - 1) : null,
                        ),
                        Text("Page $_currentPage of $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages && !_isLoading ? () => _fetchLedger(page: _currentPage + 1) : null,
                        ),
                      ],
                    ),
                  )
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> pt) {
    final entryType = pt['entryType'] ?? 'UNKNOWN';
    final note = pt['note'] ?? '';
    final createdAtStr = pt['createdAt'] ?? '';
    
    num amount = 0;
    if (pt['amount'] != null) {
      final a = pt['amount'];
      amount = a is num ? a : num.tryParse(a.toString()) ?? 0;
    }
    
    num balanceAfter = 0;
    if (pt['balanceAfter'] != null) {
       final ba = pt['balanceAfter'];
       balanceAfter = ba is num ? ba : num.tryParse(ba.toString()) ?? 0;
    }

    String displayDate = createdAtStr;
    try {
       final date = DateTime.parse(createdAtStr);
       displayDate = DateFormat('dd MMM yvyy, hh:mm a').format(date.toLocal());
    } catch (_) {}

    final bool isEarned = amount > 0;
    final Color iconColor = isEarned ? Colors.green : Colors.blue;
    final IconData icon = isEarned ? Icons.add_circle : Icons.remove_circle;

    // Safely extract the reference ID. Sometimes it's called refId, sometimes billId.
    dynamic rawRef = pt['refId'] ?? pt['billId'];
    String? finalBillId;
    if (rawRef is Map) {
      finalBillId = rawRef['_id']?.toString();
    } else if (rawRef != null) {
      finalBillId = rawRef.toString();
    }

    return InkWell(
      onTap: (finalBillId != null && entryType == 'COMMISSION_EARNED') ? () {
         print("Tapped COMMISSION_EARNED Entry. Final ID resolved to: $finalBillId. Raw Ledger Entry: $pt");
         Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: finalBillId!))
         );
      } : (entryType == 'COMMISSION_EARNED' ? () {
         print("Tapped COMMISSION_EARNED Entry but could not resolve ID! Raw Entry: $pt");
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot load bill details: Missing ID")));
      } : null),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      entryType.replaceAll("_", " "),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "${isEarned ? '+' : ''}₹${amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isEarned ? Colors.green : Colors.blue.shade700,
                      ),
                    ),
                    if (finalBillId != null && entryType == 'COMMISSION_EARNED') const Icon(Icons.chevron_right, color: Colors.grey)
                  ]
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            if (note.isNotEmpty) ...[
               Text("Note: $note", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
               const SizedBox(height: 4),
            ],
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text(displayDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("C.Bal: ₹${balanceAfter.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
               ],
            )
          ],
        )
      ),
    );
  }
}
