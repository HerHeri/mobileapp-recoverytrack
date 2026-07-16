import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../layout/main_layout.dart';
import '../widgets/search_card.dart';
import '../widgets/result_card.dart';
import '../../../models/kendaraan.dart';
import '../../../services/kendaraan_service.dart';
import '../../../services/update_service.dart';
import '../../../services/keyboard_setting_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/update_dialog.dart';
import '../../../widgets/custom_keyboard.dart';
import '../../../widgets/profile_incomplete_banner.dart';
import 'keyboard_setting_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  // --- Search state (unchanged) ---
  List<Kendaraan> _results = [];
  SearchMeta? _meta;
  bool _isLoading = false;
  String? _errorTitle;
  String? _errorMessage;
  bool _hasSearched = false;
  bool _hasResolvedSearch = false;

  // --- Keyboard state ---
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _filter = "no_polisi";

  int _keyboardType = 0; // 0 = system, 1-5 = custom
  double _keyboardHeight = 280;
  double _textSize = 20;
  bool _vibrationEnabled = true;
  bool _keyboardVisible = false;

  late AnimationController _animController;
  late Animation<double> _animSlide;

  // Debounce
  Timer? _debounce;
  Timer? _focusTimer;
  bool _updateChecked = false;
  int _searchRequestId = 0;
  bool _isSearchInFlight = false;

  // --- Search cache (local caching) ---
  Map<String, List<Kendaraan>> _searchCache = {};
  Map<String, SearchMeta?> _searchMetaCache = {};

  // --- Profile completeness state ---
  List<String> _missingDocuments = [];
  bool _profileCheckDone = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animSlide = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadSettings();
    _checkForAppUpdate();
    _checkProfileCompleteness();
  }

  Future<void> _loadSettings() async {
    final type = await KeyboardSettingService.getKeyboardType();
    final height = await KeyboardSettingService.getKeyboardHeight();
    final textSize = await KeyboardSettingService.getTextSize();
    final vibration = await KeyboardSettingService.getVibrationEnabled();
    final keepScreenOn = await KeyboardSettingService.getKeepScreenOn();

    setState(() {
      _keyboardType = type;
      _keyboardHeight = height;
      _textSize = textSize;
      _vibrationEnabled = vibration;
      _keyboardVisible = type > 0;
    });

    if (_keyboardVisible) {
      _animController.value = 1.0;
    }

    _applyKeepScreenOn(keepScreenOn);
    _scheduleSearchFocus();
  }

  void _scheduleSearchFocus() {
    if (_profileCheckDone && _missingDocuments.isNotEmpty) return;
    _focusTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  void _applyKeepScreenOn(bool enable) {
    if (enable) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _refreshSettings() {
    _loadSettings();
  }

  void _onFilterChange(String newFilter) {
    // Clear cache saat filter berubah karena hasil akan berbeda
    _clearSearchCache();
    setState(() => _filter = newFilter);
    _handleSearch(_controller.text, newFilter);
  }

  String _normalizeSearchQuery(String query) {
    return query.trim().toUpperCase();
  }

  /// Generate cache key dari query dan filter
  String _generateCacheKey(String query, String filter) {
    return '$filter:${_normalizeSearchQuery(query)}';
  }

  /// Ambil hasil dari cache jika tersedia
  Map<String, dynamic>? _getCachedResult(String query, String filter) {
    final key = _generateCacheKey(query, filter);
    final cachedData = _searchCache[key];
    final cachedMeta = _searchMetaCache[key];

    if (cachedData != null && cachedMeta != null) {
      return {'data': cachedData, 'meta': cachedMeta};
    }
    return null;
  }

  /// Simpan hasil ke cache
  void _saveCacheResult(
    String query,
    String filter,
    List<Kendaraan> data,
    SearchMeta? meta,
  ) {
    final key = _generateCacheKey(query, filter);
    _searchCache[key] = data;
    _searchMetaCache[key] = meta;
  }

  Map<String, dynamic>? _getPrefixCachedResult(String query, String filter) {
    final normalizedQuery = _normalizeSearchQuery(query);
    if (normalizedQuery.length < 3) {
      return null;
    }

    final prefix = '$filter:';
    final matchingKeys =
        _searchCache.keys.where((key) => key.startsWith(prefix)).toList()
          ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in matchingKeys) {
      final cachedQuery = key.substring(prefix.length);
      final cachedMeta = _searchMetaCache[key];
      final cachedData = _searchCache[key];

      if (cachedData == null || cachedMeta == null) {
        continue;
      }

      final normalizedCachedQuery = _normalizeSearchQuery(cachedQuery);
      if (normalizedCachedQuery.isEmpty ||
          normalizedCachedQuery.length >= normalizedQuery.length ||
          !normalizedQuery.startsWith(normalizedCachedQuery)) {
        continue;
      }

      final filteredData = _filterResultsByQuery(
        cachedData,
        normalizedQuery,
        filter,
      );

      if (filteredData.isNotEmpty) {
        return {'data': filteredData, 'meta': cachedMeta};
      }
    }

    return null;
  }

  List<Kendaraan> _filterResultsByQuery(
    List<Kendaraan> source,
    String query,
    String filter,
  ) {
    final normalizedQuery = _normalizeSearchQuery(query);

    return source.where((item) {
      final values = <String>[];
      switch (filter) {
        case 'no_polisi':
          values.add(_normalizeSearchQuery(item.noPolisi));
          break;
        case 'no_mesin':
          values.add(_normalizeSearchQuery(item.noMesin ?? ''));
          break;
        case 'no_rangka':
          values.add(_normalizeSearchQuery(item.noRangka ?? ''));
          break;
        default:
          return false;
      }

      return values.any((value) => value.contains(normalizedQuery));
    }).toList();
  }

  /// Clear cache (misal saat filter berubah)
  void _clearSearchCache() {
    _searchCache.clear();
    _searchMetaCache.clear();
  }

  String _friendlySearchMessage(Object value) {
    final message = value.toString().replaceAll('Exception: ', '').trim();
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('unauthenticated')) {
      return 'Silakan login kembali untuk melanjutkan pencarian.';
    }

    if (lowerMessage.contains('error') ||
        lowerMessage.contains('exception') ||
        lowerMessage.contains('bermasalah')) {
      return 'Pencarian belum dapat diproses. Silakan coba lagi.';
    }

    return message.isEmpty
        ? 'Pencarian belum dapat diproses. Silakan coba lagi.'
        : message;
  }

  /// Check if the user's profile documents are complete.
  /// If not, set [_missingDocuments] so the banner is shown.
  Future<void> _checkProfileCompleteness() async {
    try {
      final response = await AuthService.getProfile();
      final data =
          (response['data'] as Map<String, dynamic>?) ??
          (response['user'] as Map<String, dynamic>?) ??
          response;

      final missing = <String>[];
      if (data['ktp_photo'] == null || data['ktp_photo'].toString().isEmpty) {
        missing.add('Foto KTP');
      }
      if (data['selfie_ktp_photo'] == null ||
          data['selfie_ktp_photo'].toString().isEmpty) {
        missing.add('Selfie dengan KTP');
      }
      if (data['surat_tugas_photo'] == null ||
          data['surat_tugas_photo'].toString().isEmpty) {
        missing.add('Surat Tugas');
      }
      if (data['sppi_photo'] == null || data['sppi_photo'].toString().isEmpty) {
        missing.add('Foto SPPI');
      }

      if (mounted) {
        setState(() {
          _missingDocuments = missing;
          _profileCheckDone = true;
        });
        if (missing.isNotEmpty) {
          _focusNode.unfocus();
        }
      }
    } catch (_) {
      // If profile check fails, keep search available and show the server message later.
      if (mounted) setState(() => _profileCheckDone = true);
    }
  }

  // --- Search logic with debounce & local cache ---
  Future<void> _handleSearch(String query, String filter) async {
    _debounce?.cancel();
    if (_profileCheckDone && _missingDocuments.isNotEmpty) {
      return;
    }
    final normalizedQuery = query.trim();
    final requestId = ++_searchRequestId;

    if (normalizedQuery.length < 3) {
      KendaraanService.cancelSearch();
      setState(() {
        _results = [];
        _meta = null;
        _hasSearched = false;
        _hasResolvedSearch = false;
        _errorTitle = null;
        _errorMessage = null;
        _isLoading = false;
        _isSearchInFlight = false;
      });
      return;
    }

    final cachedResult = _getCachedResult(normalizedQuery, filter);
    if (cachedResult != null) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = cachedResult['data'] as List<Kendaraan>;
        _meta = cachedResult['meta'] as SearchMeta?;
        _isLoading = false;
        _hasSearched = true;
        _hasResolvedSearch = true;
        _errorTitle = null;
        _errorMessage = null;
      });
      return;
    }

    final prefixCachedResult = _getPrefixCachedResult(normalizedQuery, filter);
    if (prefixCachedResult != null) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = prefixCachedResult['data'] as List<Kendaraan>;
        _meta = prefixCachedResult['meta'] as SearchMeta?;
        _isLoading = false;
        _hasSearched = true;
        _hasResolvedSearch = true;
        _errorTitle = null;
        _errorMessage = null;
      });
      return;
    }

    if (_isSearchInFlight) {
      KendaraanService.cancelSearch();
    }

    _debounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _isLoading = true;
        _errorTitle = null;
        _errorMessage = null;
        _hasSearched = true;
        _hasResolvedSearch = false;
        _isSearchInFlight = true;
      });

      try {
        final response = await KendaraanService.search(
          normalizedQuery,
          field: filter,
        );
        if (!mounted || requestId != _searchRequestId) return;

        final results = response['data'] as List<Kendaraan>;
        final meta = response['meta'] as SearchMeta;

        // Simpan ke cache
        _saveCacheResult(normalizedQuery, filter, results, meta);

        setState(() {
          _results = results;
          _meta = meta;
          _isLoading = false;
          _hasResolvedSearch = true;
          _isSearchInFlight = false;
          _errorTitle = null;
          _errorMessage = null;
        });
        unawaited(ResultCard.preloadLocation());
      } on SearchCancelledException {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasResolvedSearch = true;
          _isSearchInFlight = false;
        });
      } on SearchAccessException catch (e) {
        if (!mounted || requestId != _searchRequestId) return;
        setState(() {
          _isLoading = false;
          _hasResolvedSearch = true;
          _isSearchInFlight = false;
          _errorTitle = e.title;
          _errorMessage = e.message;
        });
      } catch (e) {
        if (!mounted || requestId != _searchRequestId) return;
        setState(() {
          _isLoading = false;
          _hasResolvedSearch = true;
          _isSearchInFlight = false;
          _errorTitle = 'Pencarian Belum Tersedia';
          _errorMessage = _friendlySearchMessage(e);
        });
      }
    });
  }

  Future<void> _checkForAppUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      final updateData = await UpdateService.checkUpdate(
        currentVersion: currentVersion,
        currentVersionCode: currentVersionCode,
      );

      if (updateData != null && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(
            currentVersion: currentVersion,
            currentVersionCode: currentVersionCode,
          ),
        );
      }
    } catch (_) {}

    _scheduleSearchFocus();
  }

  // --- Custom keyboard callbacks ---
  void _onChar(String char) {
    if (char == '⌫') {
      final text = _controller.text;
      if (text.isNotEmpty) {
        final selection = _controller.selection;
        if (selection.start != selection.end) {
          _controller.text =
              text.substring(0, selection.start) +
              text.substring(selection.end);
          _controller.selection = TextSelection.collapsed(
            offset: selection.start,
          );
        } else if (selection.start > 0) {
          _controller.text =
              text.substring(0, selection.start - 1) +
              text.substring(selection.start);
          _controller.selection = TextSelection.collapsed(
            offset: selection.start - 1,
          );
        }
      }
    } else {
      final text = _controller.text;
      final selection = _controller.selection;
      final start = selection.start;
      final end = selection.end;
      _controller.text = text.substring(0, start) + char + text.substring(end);
      _controller.selection = TextSelection.collapsed(
        offset: start + char.length,
      );
    }
    // Trigger debounced search
    _handleSearch(_controller.text, _filter);
  }

  void _onClear() {
    _controller.clear();
    _handleSearch('', _filter);
  }

  void _toggleKeyboard() {
    if (_keyboardVisible) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _keyboardVisible = false;
          });
          _focusNode.unfocus();
        }
      });
    } else {
      setState(() {
        _keyboardVisible = true;
      });
      _animController.forward();
      _scheduleSearchFocus();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeyboardSettingPage()),
    );
    _refreshSettings();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchRequestId++;
    KendaraanService.cancelSearch();
    _focusTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    _clearSearchCache();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomKeyboard = _keyboardType > 0;
    final theme = Theme.of(context);
    final keyboardBottomPadding = MediaQuery.viewPaddingOf(context).bottom > 0
        ? 1.0
        : 2.0;

    return MainLayout(
      activeIndex: 1,
      contentPadding: EdgeInsets.zero,
      onKeyboardSettings: _openSettings,
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const searchAreaHeight = 76.0;
            const keyboardToggleHeight = 28.0;
            const minimumResultHeight = 90.0;
            final availableKeyboardHeight =
                (constraints.maxHeight -
                        searchAreaHeight -
                        keyboardToggleHeight -
                        keyboardBottomPadding -
                        minimumResultHeight)
                    .clamp(0.0, 420.0)
                    .toDouble();
            final finalKeyboardHeight = _keyboardHeight
                .clamp(0.0, availableKeyboardHeight)
                .toDouble();

            final isProfileIncomplete =
                _profileCheckDone && _missingDocuments.isNotEmpty;

            return Column(
              children: [
                // --- Profile incomplete banner (blocks search) ---
                if (isProfileIncomplete)
                  ProfileIncompleteBanner(missingDocuments: _missingDocuments),

                // --- Results area (Expanded so it takes remaining space) ---
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, resultConstraints) {
                      final compactResults = resultConstraints.maxHeight < 230;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(9, 2, 9, 0),
                        child: _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 80,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorTitle ??
                                            "Pencarian Belum Tersedia",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              )
                            : !_hasSearched
                            ? const SizedBox.shrink()
                            : !_hasResolvedSearch
                            ? const SizedBox.shrink()
                            : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Data tidak ditemukan",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  return ResultCard(
                                    kendaraan: _results[index],
                                    meta: _meta,
                                    compact: compactResults,
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),

                // --- Search card (compact) — blocked when profile incomplete ---
                AbsorbPointer(
                  absorbing: isProfileIncomplete,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isProfileIncomplete ? 0.4 : 1.0,
                    child: SearchCard(
                      onSearch: _handleSearch,
                      controller: _controller,
                      filter: _filter,
                      onFilterChanged: _onFilterChange,
                      readOnly: isCustomKeyboard && _keyboardVisible,
                      focusNode: _focusNode,
                      textSize: (_textSize * 0.65).clamp(18.0, 32.0),
                    ),
                  ),
                ),

                // --- Keyboard toggle (only when custom) ---
                if (isCustomKeyboard && !isProfileIncomplete)
                  GestureDetector(
                    onTap: _toggleKeyboard,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        _keyboardVisible
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),

                // --- Custom Keyboard ---
                if (isCustomKeyboard && !isProfileIncomplete)
                  SizeTransition(
                    sizeFactor: _animSlide,
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: keyboardBottomPadding),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                        child: CustomKeyboard(
                          layoutType: _keyboardType,
                          height: finalKeyboardHeight,
                          textSize: (_textSize * 0.65).clamp(18.0, 32.0),
                          vibrationEnabled: _vibrationEnabled,
                          keyboardBackground:
                              theme.colorScheme.surfaceContainerLow,
                          keyBackground:
                              theme.colorScheme.surfaceContainerHighest,
                          actionKeyBackground:
                              theme.colorScheme.primaryContainer,
                          keyBorder: theme.colorScheme.outlineVariant,
                          keyForeground: theme.colorScheme.onSurface,
                          callbacks: KeyboardCallbacks(
                            onClear: _onClear,
                            onChar: _onChar,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
