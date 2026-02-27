import 'package:flutter/material.dart';

Widget buildHeader(String title, String subtitle) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(25),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

Widget buildBottomButton(
    BuildContext context, String text, String route) {
  return Padding(
    padding: const EdgeInsets.all(15),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    ),
  );
}