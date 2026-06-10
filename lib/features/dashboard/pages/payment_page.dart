import 'package:flutter/material.dart';
import '../../../layout/main_layout.dart';
import 'package_list_page.dart';
import 'transaction_history_page.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            /// PAKET (termasuk gratis — perlu verifikasi admin)
            _menuCard(
              context,
              icon: Icons.shopping_cart,
              title: "Paket",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PackageListPage()),
                );
              },
            ),

            /// TRANSAKSI
            _menuCard(
              context,
              icon: Icons.receipt_long,
              title: "Transaksi",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              // Text(
              //   // description,
              //   textAlign: TextAlign.center,
              //   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
