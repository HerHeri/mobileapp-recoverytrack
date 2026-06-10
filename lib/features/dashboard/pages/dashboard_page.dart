import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../layout/main_layout.dart';
import '../widgets/search_card.dart';
import '../widgets/meta_bar.dart';
import '../widgets/result_card.dart';
import '../widgets/typing_hint.dart';
import '../../../models/kendaraan.dart';
import '../../../services/kendaraan_service.dart';
import '../../../services/update_service.dart';
import '../../../services/keyboard_setting_service.dart';
import '../../../widgets/update_dialog.dart';
import '../../../widgets/custom_keyboard.dart';
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
  String? _errorMessage;
  bool _hasSearched = false;

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
  bool _updateChecked = false;

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

  // --- Search logic with debounce ---
  Future<void> _handleSearch(String query, String filter) async {
    // Cancel any pending debounce
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _meta = null;
        _hasSearched = false;
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    // Debounce 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final response = await KendaraanService.search(query, field: filter);
        if (!mounted) return;
        setState(() {
          _results = response['data'] as List<Kendaraan>;
          _meta = response['meta'] as SearchMeta;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(
            currentVersion: currentVersion,
            currentVersionCode: currentVersionCode,
          ),
        );
      }
    } catch (_) {}
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
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeyboardSettingPage()),
    );
    _refreshSettings();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  double _maxKeyboardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.38;
  }

  @override
  Widget build(BuildContext context) {
    final isCustomKeyboard = _keyboardType > 0;
    final finalKeyboardHeight = max<double>(
      160,
      min(_keyboardHeight, _maxKeyboardHeight(context)),
    );

    return MainLayout(
      activeIndex: 1,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: "Setting Keyboard",
          onPressed: _openSettings,
        ),
      ],
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // --- Results area (Expanded so it takes remaining space) ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 80,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Akses Dibatasi",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3436),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    )
                  : !_hasSearched
                  ? ListView(children: const [TypingHint()])
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Data tidak ditemukan",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
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
                        );
                      },
                    ),
            ),

            // --- Meta bar ---
            MetaBar(meta: _meta, isLoading: _isLoading),

            // --- Search card (compact) ---
            SearchCard(
              onSearch: _handleSearch,
              controller: _controller,
              filter: _filter,
              onFilterChanged: (v) {
                setState(() => _filter = v);
                _handleSearch(_controller.text, v);
              },
              readOnly: isCustomKeyboard && _keyboardVisible,
              focusNode: isCustomKeyboard ? _focusNode : null,
              textSize: _textSize,
            ),

            // --- Keyboard toggle (only when custom) ---
            if (isCustomKeyboard)
              GestureDetector(
                onTap: _toggleKeyboard,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey.shade100,
                  child: Icon(
                    _keyboardVisible
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),

            // --- Custom Keyboard ---
            if (isCustomKeyboard)
              SizeTransition(
                sizeFactor: _animSlide,
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  left: false,
                  right: false,
                  child: CustomKeyboard(
                    layoutType: _keyboardType,
                    height: finalKeyboardHeight,
                    textSize: _textSize,
                    vibrationEnabled: _vibrationEnabled,
                    callbacks: KeyboardCallbacks(
                      onClear: _onClear,
                      onChar: _onChar,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
