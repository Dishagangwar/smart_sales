import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_sales/core/storage/storage_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isSuperAdmin = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await StorageService().getRole();
    if (mounted) {
      setState(() {
        _isSuperAdmin = (role == 'SUPER_ADMIN');
      });
    }
  }

  Future<void> _exportData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    
    try {
      final token = await StorageService().getToken();
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/reports/export"), headers: {"Authorization": "Bearer $token"});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> bills = decoded['data'] ?? [];
        
        if (bills.isEmpty) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export")));
           return;
        }

        // CSV Headers
        List<List<dynamic>> rows = [
           ["Bill ID", "Date", "Customer Name", "Customer Mobile", "Payment Mode", "Grand Total", "Amount Paid", "Outstanding Balance", "Created By"]
        ];
        
        for (var bill in bills) {
           final date = bill['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(bill['createdAt']).toLocal()) : '';
           
           final dynamic customerRaw = bill['customerId'];
           final String customerName = (customerRaw is Map) ? (customerRaw['name'] ?? '') : (customerRaw?.toString() ?? '');
           final String customerMobile = (customerRaw is Map) ? (customerRaw['mobile'] ?? '') : '';

           final dynamic adminRaw = bill['createdBy'];
           final String createdByName = (adminRaw is Map) ? (adminRaw['name'] ?? '') : (adminRaw?.toString() ?? '');
           
           final double gTotal = _parseNum(bill['grandTotal']).toDouble();
           final double aPaid = _parseNum(bill['paidAmount']).toDouble();
           final double remaining = _parseNum(bill['details']?['remainingBalance']).toDouble();

           rows.add([
              bill['billId'] ?? '',
              date,
              customerName,
              customerMobile,
              bill['paymentMode'] ?? '',
              gTotal.toStringAsFixed(2),
              aPaid.toStringAsFixed(2),
              remaining.toStringAsFixed(2),
              createdByName
           ]);
        }
        
        String csvData = const ListToCsvConverter().convert(rows);
        
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/smart_sales_report_${DateTime.now().millisecondsSinceEpoch}.csv";
        final File file = File(path);
        await file.writeAsString(csvData);
        
        await Share.shareXFiles([XFile(path)], text: 'Exported Sales Report');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: ${response.statusCode}")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          title: const Text("Advanced Analytics"),
          backgroundColor: Colors.blue,
          elevation: 0,
          actions: [
            if (_isSuperAdmin)
               _isExporting 
                 ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                 : IconButton(icon: const Icon(Icons.download), tooltip: "Export Report", onPressed: _exportData),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: "Daily Report"),
              Tab(text: "Monthly Report"),
              Tab(text: "By Category"),
              Tab(text: "Profit Margins"),
              Tab(text: "Top Customers"),
              Tab(text: "By Painter"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DailyReportTab(),
            _MonthlyReportTab(),
            _CategoryReportTab(),
            _ProfitReportTab(),
            _TopCustomersTab(),
            _PainterReportTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

final num Function(dynamic) _parseNum = (dynamic val) {
   if (val == null) return 0;
   if (val is num) return val;
   return num.tryParse(val.toString()) ?? 0;
};

Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
   return Container(
     padding: const EdgeInsets.all(15),
     decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: color.withOpacityBorder(0.1), blurRadius: 10, offset: const Offset(0, 4))]
     ),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         CircleAvatar(backgroundColor: color.withOpacityBorder(0.15), radius: 18, child: Icon(icon, color: color, size: 20)),
         const SizedBox(height: 12),
         Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
       ],
     ),
   );
}

extension ColorExtension on Color {
  Color withOpacityBorder(double opacity) {
    return this.withValues(alpha: opacity);
  }
}

// ============================================================================
// DAILY REPORT TAB
// ============================================================================

class _DailyReportTab extends StatefulWidget {
  const _DailyReportTab();
  @override
  State<_DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<_DailyReportTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _dailyReports = [];
  
  num _totalSales = 0;
  num _totalProfit = 0;
  num _totalBills = 0;

  @override
  void initState() {
    super.initState();
    _fetchDailyReports();
  }

  Future<void> _fetchDailyReports() async {
    setState(() { _isLoading = true; _error = ''; _totalSales = 0; _totalProfit = 0; _totalBills = 0; });
    try {
      final token = await StorageService().getToken();
      if (token == null) return;
      
      final String fromStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final String toStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/reports/daily?from=$fromStr&to=$toStr");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List<dynamic> data = decoded['data'] ?? [];
          num tSales = 0, tProfit = 0, tBills = 0;
          for (var day in data) {
             tSales += _parseNum(day['totalSales']);
             tProfit += _parseNum(day['totalProfit']);
             tBills += _parseNum(day['billCount']);
          }
          if (mounted) {
            setState(() {
              _dailyReports = data;
              _totalSales = tSales; _totalProfit = tProfit; _totalBills = tBills;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() { _error = "Server Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Network Error: $e"; _isLoading = false; });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _fetchDailyReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateRangeLabel = "${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}";

    return Column(
      children: [
         InkWell(
           onTap: () => _selectDateRange(context),
           child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Showing data for", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(dateRangeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Icon(Icons.edit_calendar, color: Colors.blue)
                ],
              ),
           ),
         ),
         Expanded(
           child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty 
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard("Total Revenue", "₹ ${_totalSales.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.blue)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildSummaryCard("Total Profit", "₹ ${_totalProfit.toStringAsFixed(0)}", Icons.trending_up, Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                             children: [
                                Expanded(child: _buildSummaryCard("Bills Generated", _totalBills.toStringAsFixed(0), Icons.receipt_long, Colors.purple)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildSummaryCard("Avg Order Val", _totalBills > 0 ? "₹ ${(_totalSales / _totalBills).toStringAsFixed(0)}" : "₹ 0", Icons.insights, Colors.orange)),
                             ]
                          ),

                          const SizedBox(height: 25),
                          const Text("Daily Revenue vs Profit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 15),
                          
                          if (_dailyReports.isEmpty)
                             Container(height: 250, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Center(child: Text("No daily data", style: TextStyle(color: Colors.grey))))
                          else
                             _buildDailyChart(),
                        ],
                      ),
                    )
         )
      ],
    );
  }

  Widget _buildDailyChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 30, right: 15, left: 5, bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxYValue(_dailyReports),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
               getTooltipColor: (_) => Colors.blueGrey,
               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final String dateLabel = _dailyReports[group.x.toInt()]['_id'] ?? '';
                  return BarTooltipItem('$dateLabel\n${rodIndex == 0 ? "Sales" : "Profit"}: ₹${rod.toY.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
               }
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int idx = value.toInt();
                  if (idx >= 0 && idx < _dailyReports.length) {
                    final String rawDate = _dailyReports[idx]['_id'] ?? '';
                    String shortDate = rawDate;
                    try { shortDate = DateFormat('MMM d').format(DateTime.parse(rawDate)); } catch (_) {}
                    if (_dailyReports.length > 7 && idx % 2 != 0) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, space: 10, child: Text(shortDate, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)));
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value == 0) return const SizedBox.shrink();
                   String text = value.toStringAsFixed(0);
                   if (value >= 1000) text = "${(value / 1000).toStringAsFixed(1)}k";
                   return SideTitleWidget(meta: meta, space: 8, child: Text("₹$text", style: const TextStyle(fontSize: 10, color: Colors.grey)));
                },
                reservedSize: 45,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          barGroups: List.generate(_dailyReports.length, (index) {
             final double sales = _parseNum(_dailyReports[index]['totalSales']).toDouble();
             final double profit = _parseNum(_dailyReports[index]['totalProfit']).toDouble();
             return BarChartGroupData(
               x: index,
               barRods: [
                 BarChartRodData(toY: sales, color: Colors.blue.shade300, width: _dailyReports.length > 15 ? 4 : 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                 BarChartRodData(toY: profit, color: Colors.green.shade400, width: _dailyReports.length > 15 ? 4 : 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
               ]
             );
          }).toList()
        )
      ),
    );
  }
}

// ============================================================================
// MONTHLY REPORT TAB
// ============================================================================

class _MonthlyReportTab extends StatefulWidget {
  const _MonthlyReportTab();
  @override
  State<_MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<_MonthlyReportTab> {
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _monthlyReports = [];
  
  num _totalSales = 0;
  num _totalProfit = 0;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyReports();
  }

  Future<void> _fetchMonthlyReports() async {
    setState(() { _isLoading = true; _error = ''; _totalSales = 0; _totalProfit = 0; });
    try {
      final token = await StorageService().getToken();
      if (token == null) return;
      
      final url = Uri.parse("https://chamanmarblel.onrender.com/api/reports/monthly?year=$_selectedYear");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List<dynamic> data = decoded['data'] ?? [];
          num tSales = 0, tProfit = 0;
          for (var month in data) {
             tSales += _parseNum(month['totalSales']);
             tProfit += _parseNum(month['totalProfit']);
          }
          if (mounted) {
            setState(() {
              _monthlyReports = data;
              _totalSales = tSales; _totalProfit = tProfit;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() { _error = "Server Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Network Error: $e"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
         Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Year", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                  items: List.generate(10, (index) {
                     final int year = DateTime.now().year - index + 2; // Show +/- years
                     return DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)));
                  }),
                  onChanged: (val) {
                     if (val != null) {
                        setState(() => _selectedYear = val);
                        _fetchMonthlyReports();
                     }
                  },
                )
              ],
            ),
         ),
         Expanded(
           child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty 
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildSummaryCard("Year Total Rev", "₹ ${_totalSales.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.teal)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildSummaryCard("Year Total Profit", "₹ ${_totalProfit.toStringAsFixed(0)}", Icons.trending_up, Colors.lightGreen)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          const Text("Monthly Revenue vs Profit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 15),
                          
                          if (_monthlyReports.isEmpty)
                             Container(height: 250, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Center(child: Text("No monthly data for this year", style: TextStyle(color: Colors.grey))))
                          else
                             _buildMonthlyChart(),
                        ],
                      ),
                    )
         )
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 30, right: 15, left: 5, bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxYValue(_monthlyReports),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
               getTooltipColor: (_) => Colors.blueGrey,
               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final String monthLabel = _monthlyReports[group.x.toInt()]['_id'] ?? '';
                  return BarTooltipItem('$monthLabel\n${rodIndex == 0 ? "Sales" : "Profit"}: ₹${rod.toY.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
               }
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int idx = value.toInt();
                  if (idx >= 0 && idx < _monthlyReports.length) {
                    final String rawDate = _monthlyReports[idx]['_id'] ?? ''; // Format "2026-02"
                    String shortMonth = rawDate;
                    if (rawDate.length == 7) {
                       final parts = rawDate.split('-');
                       if (parts.length == 2) {
                          // Try to convert "02" to "Feb"
                          final mIndex = int.tryParse(parts[1]);
                          if (mIndex != null && mIndex >= 1 && mIndex <= 12) {
                             const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                             shortMonth = months[mIndex - 1];
                          }
                       }
                    }
                    return SideTitleWidget(meta: meta, space: 10, child: Text(shortMonth, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)));
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value == 0) return const SizedBox.shrink();
                   String text = value.toStringAsFixed(0);
                   if (value >= 1000) text = "${(value / 1000).toStringAsFixed(1)}k";
                   return SideTitleWidget(meta: meta, space: 8, child: Text("₹$text", style: const TextStyle(fontSize: 10, color: Colors.grey)));
                },
                reservedSize: 45,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          barGroups: List.generate(_monthlyReports.length, (index) {
             final double sales = _parseNum(_monthlyReports[index]['totalSales']).toDouble();
             final double profit = _parseNum(_monthlyReports[index]['totalProfit']).toDouble();
             return BarChartGroupData(
               x: index,
               barRods: [
                 BarChartRodData(toY: sales, color: Colors.teal.shade300, width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                 BarChartRodData(toY: profit, color: Colors.amber.shade400, width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
               ]
             );
          }).toList()
        )
      ),
    );
  }
}

// ============================================================================
// CATEGORY REPORT TAB
// ============================================================================
class _CategoryReportTab extends StatefulWidget {
  const _CategoryReportTab();
  @override
  State<_CategoryReportTab> createState() => _CategoryReportTabState();
}

class _CategoryReportTabState extends State<_CategoryReportTab> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchCategoryReports();
  }

  Future<void> _fetchCategoryReports() async {
    try {
      final token = await StorageService().getToken();
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/reports/category"), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (mounted) setState(() { _reports = decoded['data'] ?? []; _isLoading = false; });
      } else {
         if (mounted) setState(() { _error = "Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    if (_reports.isEmpty) return const Center(child: Text("No Category Data"));
    
    // Convert to PieChart segment data
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Gross Sales by Product Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(_reports.length, (i) {
                   final r = _reports[i];
                   final double val = _parseNum(r['totalSales']).toDouble();
                   return PieChartSectionData(
                     color: colors[i % colors.length],
                     value: val,
                     title: "${r['categoryName']} \n₹${val.toStringAsFixed(0)}",
                     radius: 90,
                     titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 2)])
                   );
                })
              ),
            )
          ),
          const SizedBox(height: 30),
          ...List.generate(_reports.length, (i) {
             final r = _reports[i];
             return ListTile(
                leading: CircleAvatar(backgroundColor: colors[i % colors.length], radius: 10),
                title: Text(r['categoryName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("₹ ${_parseNum(r['totalSales']).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             );
          })
        ],
      )
    );
  }
}

// ============================================================================
// PROFIT REPORT TAB
// ============================================================================
class _ProfitReportTab extends StatefulWidget {
  const _ProfitReportTab();
  @override
  State<_ProfitReportTab> createState() => _ProfitReportTabState();
}

class _ProfitReportTabState extends State<_ProfitReportTab> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchProfitReports();
  }

  Future<void> _fetchProfitReports() async {
    try {
      final token = await StorageService().getToken();
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/reports/profit"), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (mounted) setState(() { _reports = decoded['data'] ?? []; _isLoading = false; });
      } else {
         if (mounted) setState(() { _error = "Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    if (_reports.isEmpty) return const Center(child: Text("No Profit Margins Data"));
    
    // Grab the first element as per the array response
    final map = _reports.first;
    final num totalRevenue = _parseNum(map['totalRevenue']);
    final num totalCost = _parseNum(map['totalCost']);
    final num totalProfit = _parseNum(map['totalProfit']);
    final num marginPercent = _parseNum(map['marginPercent']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Global Lifetime Profit Margins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          
          Container(
             padding: const EdgeInsets.all(25),
             decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Colors.green.shade600, Colors.teal.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
               borderRadius: BorderRadius.circular(20),
               boxShadow: [BoxShadow(color: Colors.green.withOpacityBorder(0.3), blurRadius: 15, offset: const Offset(0, 8))]
             ),
             child: Column(
               children: [
                 const Text("LIFETIME MARGIN %", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                 const SizedBox(height: 10),
                 Text("${marginPercent.toStringAsFixed(2)}%", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
               ],
             ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
             children: [
               Expanded(child: _buildSummaryCard("Total Revenue", "₹ ${totalRevenue.toStringAsFixed(0)}", Icons.monetization_on, Colors.blue)),
               const SizedBox(width: 10),
               Expanded(child: _buildSummaryCard("Total Cost (COGS)", "₹ ${totalCost.toStringAsFixed(0)}", Icons.shopping_cart, Colors.orange)),
             ],
          ),
          const SizedBox(height: 10),
          _buildSummaryCard("Net Profit Accumulation", "₹ ${totalProfit.toStringAsFixed(0)}", Icons.account_balance, Colors.green),
          
          const SizedBox(height: 40),
          
          // Tiny descriptive line chart visualization of profit vs cost breakdown for aesthetics
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                   PieChartSectionData(color: Colors.green, value: totalProfit.toDouble(), title: "Profit", radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                   PieChartSectionData(color: Colors.orange, value: totalCost.toDouble(), title: "COGS", radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ]
              )
            )
          )
        ],
      ),
    );
  }
}

double _getMaxYValue(List<dynamic> data) {
  if (data.isEmpty) return 10000;
  double maxVal = 0;
  for (var r in data) {
     final s = _parseNum(r['totalSales'] ?? r['totalRevenue']).toDouble();
     if (s > maxVal) maxVal = s;
  }
  return maxVal > 0 ? (maxVal * 1.2) : 10000;
}

// ============================================================================
// TOP CUSTOMERS TAB
// ============================================================================
class _TopCustomersTab extends StatefulWidget {
  const _TopCustomersTab();
  @override
  State<_TopCustomersTab> createState() => _TopCustomersTabState();
}

class _TopCustomersTabState extends State<_TopCustomersTab> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchTopCustomers();
  }

  Future<void> _fetchTopCustomers() async {
    try {
      final token = await StorageService().getToken();
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/reports/top-customers"), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (mounted) setState(() { _customers = decoded['data'] ?? []; _isLoading = false; });
      } else {
         if (mounted) setState(() { _error = "Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
     if (_isLoading) return const Center(child: CircularProgressIndicator());
     if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
     if (_customers.isEmpty) return const Center(child: Text("No Customer Data"));
     
     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: _customers.length,
       separatorBuilder: (_, __) => const SizedBox(height: 10),
       itemBuilder: (context, index) {
          final c = _customers[index];
          double sales = 0;
          try {
             sales = _parseNum(c['totalSales'] ?? 0).toDouble();
          } catch (_) {}
          
          return Container(
             padding: const EdgeInsets.all(15),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
             child: Row(
               children: [
                 CircleAvatar(backgroundColor: Colors.amber.shade100, child: Text("#${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))),
                 const SizedBox(width: 15),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(c['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(c['mobile'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   )
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                      Text("₹ ${sales.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      Text("${c['billCount'] ?? 0} Bills", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 )
               ],
             ),
          );
       },
     );
  }
}



// ============================================================================
// PAINTER REPORT TAB
// ============================================================================
class _PainterReportTab extends StatefulWidget {
  const _PainterReportTab();
  @override
  State<_PainterReportTab> createState() => _PainterReportTabState();
}

class _PainterReportTabState extends State<_PainterReportTab> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchPainterData();
  }

  Future<void> _fetchPainterData() async {
    try {
      final token = await StorageService().getToken();
      final response = await http.get(Uri.parse("https://chamanmarblel.onrender.com/api/reports/painter"), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
         if (mounted) setState(() { _reports = decoded['data'] ?? []; _isLoading = false; });
      } else {
         if (mounted) setState(() { _error = "Error ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    if (_reports.isEmpty) return const Center(child: Text("No Painter Data"));
    
    final List<Color> colors = [Colors.indigo, Colors.teal, Colors.deepOrange, Colors.indigoAccent, Colors.purple, Colors.pink];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Sales Volume Linked by Painter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(_reports.length, (i) {
                   final r = _reports[i];
                   final double val = _parseNum(r['totalSales']).toDouble();
                   return PieChartSectionData(
                     color: colors[i % colors.length],
                     value: val,
                     title: "${r['painterName']} \n₹${val.toStringAsFixed(0)}",
                     radius: 90,
                     titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 2)])
                   );
                })
              ),
            )
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, i) {
                 final r = _reports[i];
                 return ListTile(
                    leading: CircleAvatar(backgroundColor: colors[i % colors.length], radius: 10),
                    title: Text(r['painterName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${r['billCount'] ?? 0} Associated Bills"),
                    trailing: Text("₹ ${_parseNum(r['totalSales']).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 );
              }
            )
          )
        ],
      )
    );
  }
}