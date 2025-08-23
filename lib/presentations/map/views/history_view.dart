import 'package:flutter/material.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            'Lịch sử địa điểm',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Text(
            'Danh sách các địa điểm đã đến',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
