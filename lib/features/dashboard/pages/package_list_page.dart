import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/payment_service.dart';

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
      if (!mounted) return;
      final normalizedPackages = packages
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final hasFreePackage = normalizedPackages.any((item) {
        final price = num.tryParse(item['harga_total']?.toString() ?? '0') ?? 0;
        return price == 0;
      });

      if (!hasFreePackage) {
        normalizedPackages.insert(0, <String, dynamic>{
          'id': null,
          'nama_paket': 'Paket Gratis',
          'harga_total': 0,
          'jumlah_hari': 0,
          '_is_free_package': true,
        });
      }

      setState(() {
        _packages = normalizedPackages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
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
      appBar: AppBar(
        title: const Text('Pilih Paket'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _fetchPackages,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: theme.brightness == Brightness.light
              ? const LinearGradient(
                  colors: [Color(0xFFF1F5FF), Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: _buildContent(theme, currencyFormat),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, NumberFormat currencyFormat) {
    if (_isLoading) {
      return const _PackageLoadingState();
    }

    if (_error != null) {
      return _PackageMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Paket gagal dimuat',
        message: _error!,
        buttonLabel: 'Coba lagi',
        onPressed: _fetchPackages,
      );
    }

    if (_packages.isEmpty) {
      return _PackageMessageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada paket',
        message:
            'Paket belum tersedia saat ini. Silakan periksa kembali nanti.',
        buttonLabel: 'Muat ulang',
        onPressed: _fetchPackages,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPackages,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _PackageHeader(packageCount: _packages.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 720 ? 2 : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 190,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final package = Map<String, dynamic>.from(
                      _packages[index] as Map,
                    );
                    final name =
                        package['nama_paket']?.toString() ?? 'Paket Tanpa Nama';
                    final price =
                        num.tryParse(
                          package['harga_total']?.toString() ?? '0',
                        ) ??
                        0;
                    final duration =
                        int.tryParse(
                          package['jumlah_hari']?.toString() ?? '0',
                        ) ??
                        0;

                    return _PackageCard(
                      name: name,
                      price: price,
                      duration: duration,
                      priceLabel: price == 0
                          ? 'Gratis'
                          : currencyFormat.format(price),
                      onPressed: () => _confirmPurchase(package),
                    );
                  }, childCount: _packages.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase(Map<String, dynamic> package) async {
    final theme = Theme.of(context);
    final name = package['nama_paket']?.toString() ?? 'paket ini';
    final price = num.tryParse(package['harga_total']?.toString() ?? '0') ?? 0;
    final isFree = price == 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFree ? Icons.verified_rounded : Icons.shopping_bag_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(isFree ? 'Aktifkan paket?' : 'Konfirmasi pembelian'),
          content: Text(
            isFree
                ? 'Aktifkan $name untuk akun Anda?'
                : 'Lanjutkan pembelian $name?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isFree ? 'Aktifkan' : 'Lanjutkan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (isFree || package['_is_free_package'] == true) {
        await _processFreePackage();
      } else {
        await _processPurchase(package['id']);
      }
    }
  }

  Future<void> _processFreePackage() async {
    _showProcessingDialog('Mengaktifkan paket gratis...');

    try {
      final response = await PaymentService.activateFreePackage();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Paket gratis berhasil diaktifkan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _processPurchase(int? packageId) async {
    if (packageId == null) return;

    _showProcessingDialog('Memproses paket...');

    try {
      final response = await PaymentService.buyPackage(packageId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Permintaan paket berhasil dikirim.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _showProcessingDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(dialogContext).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageHeader extends StatelessWidget {
  final int packageCount;

  const _PackageHeader({required this.packageCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536DFE).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paket Recovery Track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pilih masa aktif yang paling sesuai dengan kebutuhan Anda.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$packageCount paket',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String name;
  final num price;
  final int duration;
  final String priceLabel;
  final VoidCallback onPressed;

  const _PackageCard({
    required this.name,
    required this.price,
    required this.duration,
    required this.priceLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = price == 0;
    final accent = isFree ? const Color(0xFF119B67) : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFree
              ? accent.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFree
                      ? [const Color(0xFF16A673), const Color(0xFF52C993)]
                      : [const Color(0xFF536DFE), const Color(0xFF7C4DFF)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            isFree
                                ? Icons.card_giftcard_rounded
                                : Icons.stars_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isFree ? 'GRATIS' : 'PREMIUM',
                            style: TextStyle(
                              color: accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      priceLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PackageFeature(
                      icon: Icons.schedule_rounded,
                      label: duration > 0
                          ? 'Masa aktif $duration hari'
                          : 'Masa aktif mengikuti ketentuan paket',
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onPressed,
                        icon: Icon(
                          isFree
                              ? Icons.flash_on_rounded
                              : Icons.shopping_bag_outlined,
                          size: 18,
                        ),
                        label: Text(isFree ? 'Aktifkan Gratis' : 'Pilih Paket'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PackageFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageLoadingState extends StatelessWidget {
  const _PackageLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat paket...'),
        ],
      ),
    );
  }
}

class _PackageMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _PackageMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
