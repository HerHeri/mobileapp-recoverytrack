import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/notification_service.dart';
import '../../../services/settings_service.dart';
import '../widgets/disclaimer_card.dart';

class SearchLogDetailPage extends StatefulWidget {
  final Map<String, dynamic> logData;
  final Future<Map<String, dynamic>>? logFuture;
  final Future<Position?>? locationFuture;

  const SearchLogDetailPage({
    super.key,
    required this.logData,
    this.logFuture,
    this.locationFuture,
  });

  @override
  State<SearchLogDetailPage> createState() => _SearchLogDetailPageState();
}

class _SearchLogDetailPageState extends State<SearchLogDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSharing = false;
  late Map<String, dynamic> _logData;
  String? _whatsAppShareTemplate;
  Future<void>? _templateFuture;
  Future<void>? _logResultFuture;
  Future<void>? _locationResultFuture;
  String? _templateError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _logData = widget.logData;
    _locationResultFuture = _loadLocationResult();
    _logResultFuture = _loadLogResult();
    _templateFuture = _loadWhatsAppShareTemplate();
  }

  Future<void> _loadLocationResult() async {
    final future = widget.locationFuture;
    if (future == null) return;

    try {
      final position = await future;
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locationError =
              "Lokasi belum tersedia. Pastikan GPS dan izin lokasi aktif.";
        });
        return;
      }

      final currentData = Map<String, dynamic>.from(_logData['data'] ?? {});
      setState(() {
        _locationError = null;
        _logData = {
          ..._logData,
          'data': {
            ...currentData,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'maps_url':
                'https://www.google.com/maps?q=${position.latitude},${position.longitude}',
          },
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadWhatsAppShareTemplate() async {
    try {
      _whatsAppShareTemplate = await SettingsService.getWhatsAppShareTemplate();
      _templateError = null;
    } catch (e) {
      _whatsAppShareTemplate = null;
      _templateError = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _loadLogResult() async {
    final future = widget.logFuture;
    if (future == null) return;

    try {
      final response = await future;
      if (!mounted) return;
      final currentData = Map<String, dynamic>.from(_logData['data'] ?? {});
      final responseData = Map<String, dynamic>.from(response['data'] ?? {});
      for (final key in const ['latitude', 'longitude', 'maps_url']) {
        final value = responseData[key];
        if (value == null || value.toString().trim().isEmpty) {
          responseData.remove(key);
        }
      }
      setState(() {
        _logData = {
          ...response,
          'data': {...currentData, ...responseData},
        };
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

  Future<void> _shareToWhatsApp(Map<dynamic, dynamic> data) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      if (_whatsAppShareTemplate == null) {
        await _templateFuture;
      }
      if (_whatsAppShareTemplate == null) {
        _templateFuture = _loadWhatsAppShareTemplate();
        await _templateFuture;
      }
      await _logResultFuture;
      await _locationResultFuture;

      final template = _whatsAppShareTemplate?.trim();
      if (template == null || template.isEmpty) {
        throw Exception(
          _templateError ??
              "Kolom whatsapp_share_template belum tersedia atau masih kosong",
        );
      }

      final latestData = Map<dynamic, dynamic>.from(_logData['data'] ?? data);
      final values = _whatsAppTemplateValues(latestData);
      final message = _renderTemplate(template, values);
      final whatsappUrl = Uri.parse(
        "whatsapp://send?text=${Uri.encodeComponent(message)}",
      );
      final webUrl = Uri.parse(
        "https://wa.me/?text=${Uri.encodeComponent(message)}",
      );

      var launched = false;
      try {
        launched = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}

      if (!launched) {
        launched = await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        throw Exception("Tidak dapat membuka WhatsApp");
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _renderTemplate(String template, Map<String, String> values) {
    var message = template.replaceAll(r'\n', '\n');
    for (final entry in values.entries) {
      message = message
          .replaceAll('{{${entry.key}}}', entry.value)
          .replaceAll('{${entry.key}}', entry.value);
    }
    return message;
  }

  Map<String, String> _whatsAppTemplateValues(Map<dynamic, dynamic> data) {
    final nopol = _valueFrom(data, const ['nopol', 'no_polisi']);
    final nosin = _valueFrom(data, const ['nosin', 'no_mesin']);
    final noka = _valueFrom(data, const ['noka', 'no_rangka']);
    final tipe = _valueFrom(data, const ['tipe', 'type_motor']);
    final leasing = _valueFrom(data, const ['nama_leasing', 'leasing']);
    final cabang = _valueFrom(data, const ['nama_cabang', 'cabang']);
    final ovd = _valueFrom(data, const ['ovd', 'overdue']);
    final contactPerson = _valueFrom(data, const [
      'contact_person',
      'nama_contact_person',
      'pic',
      'no_hp',
      'nomor_hp',
      'phone',
    ]);
    final warna = _valueFrom(data, const [
      'warna',
      'warna_kendaraan',
      'warna_motor',
      'color',
    ]);
    final keterangan = _valueFrom(data, const [
      'keterangan',
      'description',
      'notes',
      'catatan',
    ]);
    final userName = _valueFrom(data, const ['user_name', 'name']);
    final directUserContact = _valueFrom(data, const ['user_contact']);
    final userPhone = _valueFrom(data, const ['user_phone', 'phone_user']);
    final userEmail = _valueFrom(data, const ['user_email', 'email']);
    final userContact = directUserContact != '-'
        ? directUserContact
        : [
            if (userPhone != '-') userPhone,
            if (userEmail != '-') userEmail,
          ].join(' | ');
    final accessDate = _valueFrom(data, const [
      'access_date',
      'created_at',
      'accessed_at',
      'tanggal_akses',
    ]);
    final latitude = _valueFrom(data, const ['latitude', 'lat']);
    final longitude = _valueFrom(data, const ['longitude', 'lng', 'lon']);
    final mapsUrl = _valueFrom(data, const ['maps_url', 'map_url']);
    final generatedMapsUrl = latitude != '-' && longitude != '-'
        ? 'https://www.google.com/maps?q=$latitude,$longitude'
        : '-';

    return {
      'nopol': nopol,
      'no_polisi': nopol,
      'nosin': nosin,
      'no_mesin': nosin,
      'noka': noka,
      'no_rangka': noka,
      'nama_stnk': _valueFrom(data, const ['nama_stnk']),
      'tipe': tipe,
      'type_motor': tipe,
      'leasing': leasing,
      'nama_leasing': leasing,
      'cabang': cabang,
      'nama_cabang': cabang,
      'ovd': ovd,
      'contact_person': contactPerson,
      'warna': warna,
      'keterangan': keterangan,
      'user_name': userName,
      'user_contact': userContact.isEmpty ? '-' : userContact,
      'user_phone': userPhone,
      'user_email': userEmail,
      'user_company': _valueFrom(data, const [
        'user_company',
        'company',
        'nama_perusahaan',
      ]),
      'access_date': accessDate,
      'created_at': accessDate,
      'latitude': latitude,
      'longitude': longitude,
      'maps_url': mapsUrl == '-' ? generatedMapsUrl : mapsUrl,
      'disclaimer': _valueFrom(data, const ['disclaimer']),
    };
  }

  Future<void> _sendNotification() async {
    final data = _logData['data'] ?? {};
    final logId = data['log_id'];
    final message = _messageController.text.trim();

    if (logId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ID Log tidak ditemukan")));
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pesan tidak boleh kosong")));
      return;
    }

    setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _logData['data'] ?? {};
    final phone = _valueFrom(data, const [
      'no_hp',
      'nomor_hp',
      'phone',
      'no_handphone',
      'contact_person',
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pencarian")),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Informasi Kendaraan"),
                _buildInfoCard([
                  _buildInfoRow("No Polisi", data['no_polisi'] ?? "-"),
                  _buildInfoRow("Tipe Motor", data['type_motor'] ?? "-"),
                  _buildInfoRow("No Mesin", data['no_mesin'] ?? "-"),
                  _buildInfoRow("No Rangka", data['no_rangka'] ?? "-"),
                  _buildInfoRow(
                    "Tahun",
                    _valueFrom(data, const [
                      'tahun',
                      'tahun_kendaraan',
                      'tahun_motor',
                      'year',
                    ]),
                  ),
                  _buildInfoRow(
                    "Warna",
                    _valueFrom(data, const [
                      'warna',
                      'warna_kendaraan',
                      'warna_motor',
                      'color',
                    ]),
                  ),
                  _buildInfoRow(
                    "No HP",
                    phone,
                    onTap: phone == "-"
                        ? null
                        : () => _openPhoneWhatsApp(phone),
                  ),
                  _buildInfoRow(
                    "Finance",
                    _valueFrom(data, const ['nama_leasing', 'leasing']),
                  ),
                  _buildInfoRow(
                    "Cabang",
                    _valueFrom(data, const ['nama_cabang', 'cabang']),
                  ),
                  _buildInfoRow("Ovd", data['ovd'] ?? "-"),
                  _buildInfoRow("No Kontrak", data['nomor_kontrak'] ?? "-"),
                  const InformationStatusRow(),
                ]),
                const SizedBox(height: 20),
                const DisclaimerCard(),
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
                  _buildInfoRow(
                    "Latitude",
                    data['latitude']?.toString() ?? "-",
                  ),
                  _buildInfoRow(
                    "Longitude",
                    data['longitude']?.toString() ?? "-",
                  ),
                ]),
                if (_locationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _locationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : () => _shareToWhatsApp(data),
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.message),
                    label: Text(
                      _isSharing
                          ? "Membuka WhatsApp..."
                          : "Bagikan via WhatsApp",
                    ),
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
                  // _buildInfoRow("Log ID", data['log_id']?.toString() ?? "-"),
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
                      onPressed: _isLoading ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Kirim"),
                    ),
                  ),
                ]),
              ],
            ),
          ),
            Positioned.fill(child: IgnorePointer(child: _WatermarkOverlay())),
          ],
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
