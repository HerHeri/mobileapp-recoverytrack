import 'package:flutter/material.dart';
import '../../../services/payment_service.dart';
import 'package:intl/intl.dart';

class PackageListPage extends StatefulWidget {
  const PackageListPage({super.key});

  @override
  State<PackageListPage> createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final packages = await PaymentService.getPackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Beli Paket")),
      body: _buildContent(theme, currencyFormat),
    );
  }

  Widget _buildContent(ThemeData theme, NumberFormat currencyFormat) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPackages,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    if (_packages.isEmpty) {
      return const Center(
        child: Text("Maaf, tidak ada paket yang tersedia saat ini."),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final package = _packages[index];
          final String name = package['nama_paket'] ?? "Paket Tanpa Nama";
          final dynamic priceRaw = package['harga_total'];
          final num price = num.tryParse(priceRaw?.toString() ?? '0') ?? 0;
          final int duration = package['jumlah_hari'] ?? 0;
          final bool isFree = price == 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff667eea), Color(0xff764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [_statItem(Icons.timer, "$duration Hari")],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isFree
                              ? const Text(
                                  "GRATIS",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                )
                              : Text(
                                  currencyFormat.format(price),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                          ElevatedButton(
                            onPressed: () => _confirmPurchase(package),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFree
                                  ? Colors.green
                                  : const Color(0xff764ba2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isFree ? "Aktifkan Gratis" : "Beli Sekarang",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmPurchase(Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Pembelian"),
          content: Text(
            "Apakah Anda yakin ingin membeli ${package['nama_paket']}?",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPurchase(package['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff764ba2),
                foregroundColor: Colors.white,
              ),
              child: const Text("Lanjutkan"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPurchase(int? packageId) async {
    if (packageId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await PaymentService.buyPackage(packageId);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Permintaan paket berhasil dikirim.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _statItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
