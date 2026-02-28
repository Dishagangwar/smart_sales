import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smart_sales/core/storage/storage_service.dart';

class NewBillStep1 extends StatefulWidget {
  @override
  State<NewBillStep1> createState() => _NewBillStep1State();
}

class _NewBillStep1State extends State<NewBillStep1> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  bool isSearchingMobile = false;

  String? selectedPainterId;
  final TextEditingController painterSearchController = TextEditingController();

  Future<Iterable<Map<String, dynamic>>> _searchDropdownApi(String query) async {
    if (query.isEmpty) return const [];
    try {
      final token = await StorageService().getToken();
      if (token == null) return const [];

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/customers/dropdown/list?search=$query");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return (decoded['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      // Return empty on error
    }
    return const [];
  }

  Future<Iterable<Map<String, dynamic>>> _searchPainterDropdownApi(String query) async {
    if (query.isEmpty) return const [];
    try {
      final token = await StorageService().getToken();
      if (token == null) return const [];

      final url = Uri.parse("https://chamanmarblel.onrender.com/api/painters/dropdown/list?search=$query");
      final response = await http.get(
        url,
        headers: {
           "Content-Type": "application/json",
           "Authorization": "Bearer $token",
        }
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return (decoded['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch(e) {
      // Silently fail autocomplete
    }
    return const [];
  }

  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentication required")));
           setState(() => isLoading = false);
        }
        return;
      }

      final bodyData = {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim()
      };
      // Note: The backend route /billing/create-or-fetch doesn't strictly log the painterId yet,
      // but we will pass it anyway so step 2 or the final bill creation can use it.
      if (selectedPainterId != null) {
        bodyData["painterId"] = selectedPainterId!;
      }

      final response = await http.post(
        Uri.parse("https://chamanmarblel.onrender.com/api/customers/billing/create-or-fetch"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true) {
        // Successfully created or fetched customer
        final customerData = decoded['data'];
        
        // Pass the customer AND painter data to Step 2
        final Map<String, dynamic> combinedArgs = {
          "customer": customerData,
          "painterId": selectedPainterId,
        };

        // NEW: If they didn't select an official Painter ID, but typed a name anyway, we pass it down
        // so Step 2 can automatically create the Painter on the backend during checkout!
        if (selectedPainterId == null && painterSearchController.text.trim().isNotEmpty) {
            combinedArgs['painterName'] = painterSearchController.text.trim();
        }

        Navigator.pushNamed(
          context, 
          '/bill2', 
          arguments: combinedArgs // Next screen can consume this if needed
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? "Failed to process customer")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    nameController.dispose();
    painterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _handleNextStep, // Replaced static navigation
              child: const Text("NEXT STEP →", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
      ),
      body: Column(
        children: [
          _header("New Bill", "Add a new Bill"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("Search / Pick Customer", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 5),
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 2) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return await _searchDropdownApi(textEditingValue.text);
                      },
                      displayStringForOption: (Map<String, dynamic> option) => "${option['name']} - ${option['mobile']}",
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 250,
                              width: MediaQuery.of(context).size.width - 40, // Matches padding
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  final num balance = option['currentBalance'] != null 
                                    ? (option['currentBalance'] is num ? option['currentBalance'] : num.tryParse(option['currentBalance'].toString()) ?? 0)
                                    : 0;
                                  final hasDebt = balance > 0;
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: const Icon(Icons.person, color: Colors.blue),
                                    ),
                                    title: Text(option['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(option['mobile'] ?? 'No mobile'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: hasDebt ? Colors.red.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Bal: ₹${balance.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: hasDebt ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() {
                          nameController.text = selection['name'] ?? '';
                          mobileController.text = selection['mobile'] ?? '';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer Auto-filled!"), backgroundColor: Colors.green));
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Search by Name or Mobile",
                            hintText: "Type at least 2 characters...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR ENTER MANUALLY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Mobile Number*",
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) return "Mobile is required";
                         if (value.length < 10) return "Must be 10 digits";
                         return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Customer Name*",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Made address completely optional and un-controlled for now since the API only requires name and mobile for create-or-fetch helper.
                    const TextField(
                      decoration: InputDecoration(
                        labelText: "Address (Optional)",
                        border: OutlineInputBorder(),
                        enabled: false, // Disabled since this is just a fast helper
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text("Link a Painter (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 5),
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 2) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return await _searchPainterDropdownApi(textEditingValue.text);
                      },
                      displayStringForOption: (Map<String, dynamic> option) => "${option['name']} - ${option['mobile']}",
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 200,
                              width: MediaQuery.of(context).size.width - 40,
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.shade50,
                                      child: const Icon(Icons.format_paint, color: Colors.indigo),
                                    ),
                                    title: Text(option['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(option['mobile'] ?? 'No mobile'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() {
                           selectedPainterId = selection['_id'];
                           painterSearchController.text = selection['name'] ?? '';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Painter Linked!"), backgroundColor: Colors.indigo));
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onChanged: (val) {
                             painterSearchController.text = val;
                             // Auto-clear selected painter ID if they start editing the field again
                             if (selectedPainterId != null) {
                                setState(() => selectedPainterId = null);
                             }
                          },
                          decoration: InputDecoration(
                            labelText: "Search Painters...",
                            hintText: "Type at least 2 characters...",
                            prefixIcon: const Icon(Icons.format_paint),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                            suffixIcon: selectedPainterId != null 
                             ? IconButton(
                                 icon: const Icon(Icons.close, color: Colors.red),
                                 onPressed: () {
                                    setState(() {
                                       selectedPainterId = null;
                                       textEditingController.clear();
                                    });
                                 },
                               )
                             : null,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget _header(String title, String subtitle) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}