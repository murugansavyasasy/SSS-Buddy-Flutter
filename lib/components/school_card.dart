import 'package:flutter/material.dart';

class SchoolCard extends StatelessWidget {
  final dynamic item;

  const SchoolCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("School Id : ${item["SchoolID"]}"),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item["isActive"].toString() == "1"
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item["isActive"].toString() == "1"
                      ? "Active"
                      : "Inactive",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            item["SchoolName"] ?? "",
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(item["ContactNumber1"] ?? ""),
          Text(item["ContactEmail"] ?? ""),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Sales Person : ${item["sales_person"] ?? ""}",
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}