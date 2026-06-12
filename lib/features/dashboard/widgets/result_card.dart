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

  static Future<void> preloadLocation() async {
    await _LocationCache.get(requestPermission: false);
  }

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  void _handleViewDetail() {
    final locationFuture = _LocationCache.get(requestPermission: true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchLogDetailPage(
          logData: {'data': widget.kendaraan.toDetailJson()},
          locationFuture: locationFuture,
          logFuture: _createLocationLog(locationFuture),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _createLocationLog(
    Future<Position?> locationFuture,
  ) async {
    var position = await locationFuture;
    position ??= await _LocationCache.get(requestPermission: true);
    return KendaraanService.logLokasi(
      query: _getHighlightValue(),
      resultsCount: 1,
      source: widget.meta?.source ?? 'database',
      responseTimeMs: widget.meta?.responseTimeMs ?? 0,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
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

    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 6 : 10),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: _handleViewDetail,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 16,
              vertical: widget.compact ? 10 : 13,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: _highlightedText(
                    context,
                    _resultValue?.trim().isNotEmpty == true
                        ? _resultValue!.trim()
                        : '-',
                    widget.meta?.query.trim() ?? '',
                  ),
                ),
              ),
            ),
          ),
        ),
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
      color: theme.colorScheme.primary,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.45),
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

class _LocationCache {
  static const _lifetime = Duration(minutes: 5);
  static Position? _position;
  static DateTime? _cachedAt;
  static Future<Position?>? _pending;

  static Position? get cachedPosition {
    final cachedAt = _cachedAt;
    if (_position == null ||
        cachedAt == null ||
        DateTime.now().difference(cachedAt) >= _lifetime) {
      return null;
    }
    return _position;
  }

  static Future<Position?> get({required bool requestPermission}) async {
    final cached = cachedPosition;
    if (cached != null) return cached;

    final pending = _pending;
    if (pending != null) {
      final result = await pending;
      if (result != null || !requestPermission) return result;
    }

    final future = _load(requestPermission: requestPermission);
    _pending = future;
    try {
      return await future;
    } finally {
      if (identical(_pending, future)) _pending = null;
    }
  }

  static Future<Position?> _load({required bool requestPermission}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      _store(lastKnown);
      return lastKnown;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 3),
        ),
      );
      _store(current);
      return current;
    } catch (_) {
      return null;
    }
  }

  static void _store(Position position) {
    _position = position;
    _cachedAt = DateTime.now();
  }
}
