import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_sales/core/storage/storage_service.dart';

void main() async {
  final token = await StorageService().getToken();
  if (token == null) {
    return;
  }
  
  final url = Uri.parse("https://chamanmarblel.onrender.com/api/reports/outstanding");
  try {
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
  } catch (e) {
    print("ERROR: $e");
  }
}
