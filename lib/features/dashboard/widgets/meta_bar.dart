// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../models/kendaraan.dart';

class MetaBar extends StatelessWidget {
  final SearchMeta? meta;
  final bool isLoading;

  const MetaBar({super.key, this.meta, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (meta == null && !isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black.withOpacity(0.03),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Chip(
              //   label: Text(
              //     isLoading
              //         ? "..."
              //         : (meta?.source.toLowerCase().contains('database') == true
              //               ? "🗄️ Database"
              //               : "⚡ Cache"),
              //   ),
              // ),
              const SizedBox(width: 8),
              if (meta != null) ...[
                Chip(label: Text(meta!.query)),
                const SizedBox(width: 8),
                // Text("${meta!.responseTimeMs.toStringAsFixed(2)}ms"),
              ],
            ],
          ),
          if (meta != null) Text("${meta!.count} hasil"),
        ],
      ),
    );
  }
}
