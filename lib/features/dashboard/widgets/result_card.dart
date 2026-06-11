import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/kendaraan.dart';
import '../pages/search_log_detail_page.dart';
import '../../../services/kendaraan_service.dart';

class ResultCard extends StatefulWidget {
  final Kendaraan kendaraan;
  final SearchMeta? meta;
  final bool compact;

  const ResultCard({
    super.key,
    required this.kendaraan,
    this.meta,
    this.compact = false,
  });

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

  String get _resultLabel {
    switch (widget.meta?.field) {
      case 'no_mesin':
        return 'Nosin';
      case 'no_rangka':
        return 'Noka';
      default:
        return 'Nopol';
    }
  }

  String? get _resultValue {
    switch (widget.meta?.field) {
      case 'no_mesin':
        return widget.kendaraan.noMesin;
      case 'no_rangka':
        return widget.kendaraan.noRangka;
      default:
        return widget.kendaraan.noPolisi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: widget.compact ? 6 : 10),
      padding: EdgeInsets.all(widget.compact ? 8 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _InlineField(
                  label: _resultLabel,
                  value: _resultValue,
                  query: widget.meta?.query,
                  emphasized: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            height: widget.compact ? 28 : 30,
            child: FilledButton.tonalIcon(
              onPressed: _isLogging ? null : _handleViewDetail,
              icon: _isLogging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text(_isLogging ? 'Memuat' : 'Lihat detail'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final String label;
  final String? value;
  final String? query;
  final bool emphasized;

  const _InlineField({
    required this.label,
    required this.value,
    this.query,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value?.trim().isNotEmpty == true ? value!.trim() : '-';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  ',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: _highlightedText(
                context,
                displayValue,
                query?.trim() ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightedText(
    BuildContext context,
    String text,
    String searchQuery,
  ) {
    final theme = Theme.of(context);
    final baseStyle = TextStyle(
      color: emphasized
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );

    if (searchQuery.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
        );
      }

      final matchEnd = matchIndex + searchQuery.length;
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchEnd),
          style: baseStyle.copyWith(
            color: theme.colorScheme.onTertiaryContainer,
            backgroundColor: theme.colorScheme.tertiaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      start = matchEnd;
    }

    return spans;
  }
}
