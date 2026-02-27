import 'package:flutter/material.dart';

class PaintersScreen extends StatelessWidget {

  final List<Map<String, String>> painters = [
    {
      "name": "Suresh M.",
      "role": "Contractor",
      "sales": "₹ 2.4L",
      "commission": "₹ 12k"
    },
    {
      "name": "Vijay Colors",
      "role": "Painter",
      "sales": "₹ 85k",
      "commission": "₹ 4k"
    },
    {
      "name": "Mahesh Art",
      "role": "Painter",
      "sales": "₹ 1.2L",
      "commission": "₹ 6.5k"
    },
    {
      "name": "Ramesh S.",
      "role": "Contractor",
      "sales": "₹ 3.1L",
      "commission": "₹ 18k"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Painters"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        onPressed: () {},
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              decoration: InputDecoration(
                hintText: "Search painter name...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: painters.length,
                itemBuilder: (context, index) {
                  final painter = painters[index];

                  return Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            painter["name"]![0],
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                        SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                painter["name"]!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              Text(
                                painter["role"]!,
                                style: TextStyle(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              painter["sales"]!,
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Comm: ${painter["commission"]!}",
                              style: TextStyle(
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}