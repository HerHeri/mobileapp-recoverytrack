import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../../../services/kendaraan_service.dart';
import '../../../services/notification_service.dart';

class HistoryLogDetailPage extends StatefulWidget {
  final int logId;

  const HistoryLogDetailPage({super.key, required this.logId});

  @override
  State<HistoryLogDetailPage> createState() => _HistoryLogDetailPageState();
}

class _HistoryLogDetailPageState extends State<HistoryLogDetailPage> {
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await KendaraanService.getHistoryLogDetail(widget.logId);
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openInGoogleMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka Maps")),
        );
      }
    }
  }

  Future<void> _shareToWhatsApp(
    String noPolisi,
    String namaStnk,
    String noMesin,
    String noRangka,
    String tipe,
    String namaLeasing,
    String namaCabang,
    String createdAt,
    String userName,
    String userPhone,
    String userMail,
    String latitude,
    String longitude,
    String userCompany,
    String disclaimer,
  ) async {
    final message =
        "Info Suntik Radar \n Nopol : $noPolisi \n Nama STNK : $namaStnk \n Nosin : $noMesin \n Noka : $noRangka \n Tipe : $tipe \n Leasing : $namaLeasing \n Cabang : $namaCabang \n Ovd : - \n Contact Person : - \n Keterangan : - \n PERHATIAN : Data yang ditampilkan bukan bukti sah identitas kendaraan tersebut menunggak angsuran, dan bukan alat untuk mengamankan kendaraan, untuk validasi wajib konfirmasi  ke perusahaan Pembiayaan terkait.\n =============== \n Telah diakses oleh $userName ($userPhone | $userMail) dari $userCompany pada tanggal $createdAt. Lokasi akses data https://www.google.com/maps?q=$latitude,$longitude.";
    final whatsappUrl = Uri.parse(
      "whatsapp://send?text=${Uri.encodeComponent(message)}",
    );
    final webUrl = Uri.parse(
      "https://wa.me/?text=${Uri.encodeComponent(message)}",
    );

    bool launched = false;
    try {
      launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
      );
    }
  }

  Future<void> _sendNotification() async {
    final data = _detailData ?? {};
    final logId = data['log_id'] ?? widget.logId;
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pesan tidak boleh kosong")));
      return;
    }

    setState(() => _isSending = true);

    try {
      await NotificationService.sendNotification(
        logId: int.parse(logId.toString()),
        message: message,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi berhasil dikirim")),
        );
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Riwayat")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetail,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    final data = _detailData ?? {};

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Informasi Kendaraan"),
              _buildInfoCard([
                _buildInfoRow("Kata Kunci", data['query'] ?? "-"),
                _buildInfoRow("No Polisi", data['no_polisi'] ?? "-"),
                _buildInfoRow("No Mesin", data['no_mesin'] ?? "-"),
                _buildInfoRow("No Rangka", data['no_rangka'] ?? "-"),
                _buildInfoRow(
                  "Finance",
                  _valueFrom(data, const ['nama_leasing', 'leasing']),
                ),
                _buildInfoRow(
                  "Cabang",
                  _valueFrom(data, const ['nama_cabang', 'cabang']),
                ),
                _buildInfoRow("Waktu", data['created_at'] ?? "-"),
              ]),
              const SizedBox(height: 20),
              Card(
                color: Colors.yellow.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    data['disclaimer'] ?? "",
                    style: TextStyle(
                      color: const Color.fromARGB(206, 255, 0, 0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Lokasi"),
                  if (data['latitude'] != null && data['longitude'] != null)
                    TextButton.icon(
                      onPressed: () => _openInGoogleMaps(
                        double.tryParse(data['latitude'].toString()),
                        double.tryParse(data['longitude'].toString()),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text("Buka di Maps"),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              _buildInfoCard([
                _buildInfoRow("Latitude", data['latitude']?.toString() ?? "-"),
                _buildInfoRow(
                  "Longitude",
                  data['longitude']?.toString() ?? "-",
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareToWhatsApp(
                    data['no_polisi'] ?? "-",
                    data['nama_stnk'] ?? "-",
                    data['no_mesin'] ?? "-",
                    data['no_rangka'] ?? "-",
                    data['type_motor'] ?? "-",
                    data['nama_leasing'] ?? "-",
                    data['nama_cabang'] ?? "-",
                    data['created_at'] ?? "-",
                    data['user_name'] ?? "-",
                    data['user_phone'] ?? "-",
                    data['user_email'] ?? "-",
                    data['latitude']?.toString() ?? "-",
                    data['longitude']?.toString() ?? "-",
                    data['user_company']?.toString() ?? "-",
                    data['disclaimer'] ?? "-",
                  ),
                  icon: const Icon(Icons.message),
                  label: const Text("Bagikan via WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              _buildSectionTitle("Wajib Mengisi Alasan"),
              _buildInfoCard([
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Masukkan alasan...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Kirim Notifikasi"),
                  ),
                ),
              ]),
            ],
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: _WatermarkOverlay())),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  String _valueFrom(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return "-";
  }

  Widget _buildInfoCard(List<Widget> children) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatermarkOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 40,
          children: List.generate(
            50,
            (index) => Transform.rotate(
              angle: -math.pi / 6,
              child: Text(
                "Data hanya bersifat informasi",
                style: TextStyle(
                  color: const Color.fromARGB(
                    201,
                    233,
                    14,
                    14,
                  ).withValues(alpha: 0.12),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
