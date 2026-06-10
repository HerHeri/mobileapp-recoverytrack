import 'package:flutter/material.dart';

class TypingHint extends StatelessWidget {
  const TypingHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),

      child: Column(
        children: const [
          Icon(Icons.keyboard, size: 60, color: Colors.grey),

          SizedBox(height: 10),

          Text(
            "Mulai Mengetik",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          SizedBox(height: 6),

          Text(
            "Ketik minimal 2 karakter untuk pencarian prefix",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
