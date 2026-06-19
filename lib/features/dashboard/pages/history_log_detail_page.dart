import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../../../services/kendaraan_service.dart';
import '../../../services/notification_service.dart';
import '../widgets/disclaimer_card.dart';

class HistoryLogDetailPage extends StatefulWidget {
  final int logId;
  final Map<String, dynamic>? initialData;

  const HistoryLogDetailPage({
    super.key,
    required this.logId,
    this.initialData,
  });

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
    final initialData = widget.initialData;
    if (initialData == null) {
      _fetchDetail();
    } else {
      _detailData = KendaraanService.normalizeHistoryDetail(initialData);
      _isLoading = false;
      _fetchDetail(showLoading: false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final data = await KendaraanService.getHistoryLogDetail(widget.logId);
      if (!mounted) return;
      setState(() {
        _detailData = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_detailData != null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
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
        "Recovery Track \n Nopol : $noPolisi \n Nama STNK : $namaStnk \n Nosin : $noMesin \n Noka : $noRangka \n Tipe : $tipe \n Leasing : $namaLeasing \n Cabang : $namaCabang \n Ovd : - \n Contact Person : - \n Keterangan : - \n PERHATIAN : Data yang ditampilkan bukan bukti sah identitas kendaraan tersebut menunggak angsuran, dan bukan alat untuk mengamankan kendaraan, untuk validasi wajib konfirmasi  ke perusahaan Pembiayaan terkait.\n =============== \n Telah diakses oleh $userName ($userPhone | $userMail) dari $userCompany pada tanggal $createdAt. Lokasi akses data https://www.google.com/maps?q=$latitude,$longitude.";
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
    final phone = _valueFrom(data, const [
      'no_hp',
      'nomor_hp',
      'phone',
      'telepon',
      'hp',
      'no_handphone',
      'contact_person',
    ]);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Informasi Kendaraan"),
              _buildInfoCard([
                // _buildInfoRow(
                //   "Kata Kunci",
                //   _valueFrom(data, const ['query', 'keyword', 'kata_kunci']),
                // ),
                _buildInfoRow(
                  "No Polisi",
                  _valueFrom(data, const ['no_polisi', 'nopol']),
                ),
                _buildInfoRow(
                  "Tipe Motor",
                  _valueFrom(data, const [
                    'type_motor',
                    'tipe_motor',
                    'tipe',
                    'type',
                  ]),
                ),
                _buildInfoRow(
                  "No Mesin",
                  _valueFrom(data, const ['no_mesin', 'nosin']),
                ),
                _buildInfoRow(
                  "No Rangka",
                  _valueFrom(data, const ['no_rangka', 'noka']),
                ),
                _buildInfoRow(
                  "Tahun",
                  _valueFrom(data, const [
                    'tahun',
                    'tahun_kendaraan',
                    'tahun_motor',
                    'tahun_pembuatan',
                    'year',
                  ]),
                ),
                _buildInfoRow(
                  "Warna",
                  _valueFrom(data, const [
                    'warna',
                    'warna_kendaraan',
                    'warna_motor',
                    'warna_unit',
                    'color',
                  ]),
                ),
                _buildInfoRow(
                  "No HP",
                  phone,
                  onTap: phone == "-" ? null : () => _openPhoneWhatsApp(phone),
                ),
                _buildInfoRow(
                  "Finance",
                  _valueFrom(data, const ['nama_leasing', 'leasing']),
                ),
                _buildInfoRow(
                  "Cabang",
                  _valueFrom(data, const ['nama_cabang', 'cabang']),
                ),
                _buildInfoRow(
                  "Ovd",
                  _valueFrom(data, const ['ovd', 'overdue']),
                ),
                _buildInfoRow(
                  "No Kontrak",
                  _valueFrom(data, const [
                    'nomor_kontrak',
                    'no_kontrak',
                    'contract_no',
                    'contract_number',
                  ]),
                ),
                const InformationStatusRow(),
              ]),
              const SizedBox(height: 16),
              const DisclaimerCard(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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

              const SizedBox(height: 16),
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
      padding: const EdgeInsets.only(bottom: 4, left: 4),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Future<void> _openPhoneWhatsApp(String phone) async {
    var normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    }
    if (normalized.isEmpty) return;

    final appUrl = Uri.parse('whatsapp://send?phone=$normalized');
    final webUrl = Uri.parse('https://wa.me/$normalized');
    var launched = false;
    try {
      launched = await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!launched) {
      launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
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
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: onTap == null
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  decoration: onTap == null ? null : TextDecoration.underline,
                ),
              ),
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
