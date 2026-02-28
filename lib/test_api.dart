import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print("Logging in to ping Export...");
  
  final loginRes = await http.post(
    Uri.parse("https://chamanmarblel.onrender.com/api/auth/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"pin": "123456"})
  );
  
  final token = jsonDecode(loginRes.body)['token'];
  
  final url = Uri.parse("https://chamanmarblel.onrender.com/api/reports/export");
  final res = await http.get(url, headers: {"Authorization": "Bearer $token"});
  
  final decoded = jsonDecode(res.body);
  final List bills = decoded['data'] ?? [];
  
  if (bills.isNotEmpty) {
      print("BILL 1: ${jsonEncode(bills.first)}");
  } else {
      print("No bills returned.");
  }
}
