import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/kendaraan.dart';
import '../pages/search_log_detail_page.dart';
import '../../../services/kendaraan_service.dart';

class ResultCard extends StatefulWidget {
  final Kendaraan kendaraan;
  final SearchMeta? meta;

  const ResultCard({super.key, required this.kendaraan, this.meta});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isLogging = false;

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleViewDetail() async {
    setState(() => _isLogging = true);

    try {
      final position = await _getCurrentLocation();

      // Data dalam card menyesuaikan hasil pencarian
      final cardData = _getHighlightValue();

      final logResponse = await KendaraanService.logLokasi(
        query: cardData,
        resultsCount: 1,
        source: widget.meta?.source ?? 'database',
        responseTimeMs: widget.meta?.responseTimeMs ?? 0,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchLogDetailPage(logData: logResponse),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  String _getHighlightValue() {
    final field = widget.meta?.field;
    if (field == 'no_mesin' && widget.kendaraan.noMesin != null) {
      return widget.kendaraan.noMesin!;
    } else if (field == 'no_rangka' && widget.kendaraan.noRangka != null) {
      return widget.kendaraan.noRangka!;
    }
    return widget.kendaraan.noPolisi;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(_getHighlightValue())),
                if (widget.kendaraan.cabang != null)
                  Text(
                    widget.kendaraan.cabang!,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLogging ? null : _handleViewDetail,
                icon: _isLogging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on, size: 18),
                label: Text(
                  _isLogging ? "Logging..." : "Lihat Detail & Log Lokasi",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldItem extends StatelessWidget {
  final String label;
  final String value;

  const FieldItem(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
