import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';
import 'package:smart_sales/screens/painter_ledger_screen.dart';

class PainterProfileScreen extends StatefulWidget {
  final Map<String, dynamic> painterData;

  const PainterProfileScreen({super.key, required this.painterData});

  @override
  State<PainterProfileScreen> createState() => _PainterProfileScreenState();
}

class _PainterProfileScreenState extends State<PainterProfileScreen> {
  final StorageService _storageService = StorageService();
  String? _userRole;
  
  bool _isLoadingSummary = true;
  String _summaryError = '';
  Map<String, dynamic>? _ledgerSummary;
  num _currentBalance = 0; // Local reflection of balance

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchLedgerSummary();
    
    // Sync initial balance from passed data
    if (widget.painterData['currentBalance'] != null) {
      final cb = widget.painterData['currentBalance'];
      _currentBalance = cb is num ? cb : num.tryParse(cb.toString()) ?? 0;
    }
  }

  Future<void> _loadUserRole() async {
    final role = await _storageService.getRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  Future<void> _fetchLedgerSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = '';
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      
      final painterId = widget.painterData['_id'];
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/painters/$painterId/ledger/summary");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
           setState(() {
             _ledgerSummary = decoded['data'];
             // Sync the balance natively
             if (_ledgerSummary?['balance'] != null) {
               final b = _ledgerSummary!['balance'];
               _currentBalance = b is num ? b : num.tryParse(b.toString()) ?? 0;
             }
             _isLoadingSummary = false;
           });
        } else {
          setState(() {
            _summaryError = "Failed to load summary";
            _isLoadingSummary = false;
          });
        }
      } else {
        setState(() {
          _summaryError = "Failed to load summary";
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = "Network error";
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _recomputeBalance() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      
      final painterId = widget.painterData['_id'];
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recomputing balance...")));
      
      final response = await http.get(
        Uri.parse("https://chamanmarblel.onrender.com/api/painters/$painterId/recompute-balance"),
        headers: {"Authorization": "Bearer $token"},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Balance synced successfully!"), backgroundColor: Colors.green));
        _fetchLedgerSummary();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to recompute"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePainter() async {
    if (_currentBalance > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cannot delete a painter with a pending commission balance. Please pay out commissions first."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contractor?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to remove this painter? This action cannot be fully undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      final token = await _storageService.getToken();
      if (token == null) return;
      
      final painterId = widget.painterData['_id'];
      final response = await http.delete(
        Uri.parse("https://chamanmarblel.onrender.com/api/painters/$painterId"),
        headers: {"Authorization": "Bearer $token"},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true); // Pop back to list and trigger refresh
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Painter deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to delete")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showPayCommissionDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    bool isSubmitting = false;

    // Default the note
    noteController.text = "Commission Payout";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.payment, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text("Pay Commission", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Available Pending: ₹${_currentBalance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Payout Amount",
                      border: OutlineInputBorder(),
                      prefixText: "₹ ",
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Note / Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: isSubmitting ? null : () async {
                    final amountText = amountController.text.trim();
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter an amount")));
                      return;
                    }
                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid amount")));
                      return;
                    }
                    if (amount > _currentBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot pay more than pending balance!")));
                      return;
                    }

                    setModalState(() => isSubmitting = true);

                    try {
                       final token = await _storageService.getToken();
                       final painterId = widget.painterData['_id'];
                       final response = await http.post(
                         Uri.parse("https://chamanmarblel.onrender.com/api/painters/$painterId/pay-commission"),
                         headers: {
                           "Content-Type": "application/json",
                           "Authorization": "Bearer $token",
                         },
                         body: jsonEncode({
                           "amount": amount,
                           "note": noteController.text.trim()
                         }),
                       );

                       final decoded = jsonDecode(response.body);
                       if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Commission paid successfully!"), backgroundColor: Colors.green));
                         _fetchLedgerSummary(); // Refresh data
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed to process payment")));
                         setModalState(() => isSubmitting = false);
                       }
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                       setModalState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : const Text("Confirm Payment", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.painterData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painter Profile"),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          if (_userRole == "SUPER_ADMIN")
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: "Recompute Balance",
              onPressed: _recomputeBalance,
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile block
            Container(
              width: double.infinity,
              color: Colors.indigo,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
              child: Column(
                children: [
                   const CircleAvatar(
                     radius: 40,
                     backgroundColor: Colors.white,
                     child: Icon(Icons.format_paint, size: 45, color: Colors.indigo),
                   ),
                   const SizedBox(height: 15),
                   Text(p['name'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 5),
                   Text(p['mobile'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                   const SizedBox(height: 10),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       "Lifetime Earned: ₹${((p['totalCommissionEarned'] is num) ? p['totalCommissionEarned'] : num.tryParse(p['totalCommissionEarned']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}", 
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                     ),
                   )
                ],
              ),
            ),
            
            // Ledger Summary Block
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Text("Ledger Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                   const SizedBox(height: 15),
                   
                   if (_isLoadingSummary)
                     const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                   else if (_summaryError.isNotEmpty)
                     Center(child: Text(_summaryError, style: const TextStyle(color: Colors.red)))
                   else
                     _buildSummaryCards(),

                   const SizedBox(height: 25),
                   
                   // Action Buttons
                   ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.indigo.shade200))
                      ),
                      onPressed: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (context) => PainterLedgerScreen(painterData: p))
                         );
                      }, 
                      icon: const Icon(Icons.receipt_long), 
                      label: const Text("View Full Ledger", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),

                       // Pay Commission button exclusively for SUPER_ADMIN
                   if (_userRole == "SUPER_ADMIN") ...[
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentBalance > 0 ? Colors.green : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        onPressed: _currentBalance > 0 ? _showPayCommissionDialog : null, 
                        icon: const Icon(Icons.payment, color: Colors.white), 
                        label: Text(
                          _currentBalance > 0 ? "Pay Commission" : "No Pending Balance", 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      // Soft Delete Safety Boundary
                      TextButton.icon(
                        onPressed: _deletePainter,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        label: const Text("Delete Contractor", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                      )
                   ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    num totalEarned = 0;
    num totalPaid = 0;
    
    if (_ledgerSummary != null) {
      final c = _ledgerSummary!['totalCredits'];
      totalEarned = c is num ? c : num.tryParse(c.toString()) ?? 0;
      
      final d = _ledgerSummary!['totalDebits'];
      totalPaid = d is num ? d : num.tryParse(d.toString()) ?? 0;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _currentBalance > 0 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _currentBalance > 0 ? Colors.red.shade200 : Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text("Pending Outstanding", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                   const SizedBox(height: 5),
                   Text("₹${_currentBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _currentBalance > 0 ? Colors.red : Colors.green)),
                 ],
               ),
               Icon(Icons.account_balance_wallet, size: 40, color: _currentBalance > 0 ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat("Total Earned", "₹${totalEarned.toStringAsFixed(2)}", Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildMiniStat("Total Paid", "₹${totalPaid.toStringAsFixed(2)}", Colors.blue),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMiniStat(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis,),
        ],
      ),
    );
  }
}
