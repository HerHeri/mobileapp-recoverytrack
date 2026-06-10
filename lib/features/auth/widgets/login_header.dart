import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.lock, size: 48),

        SizedBox(height: 10),

        Text(
          "Masuk ke Sistem",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 4),

        Text(
          "Silakan login untuk mengakses dashboard",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
