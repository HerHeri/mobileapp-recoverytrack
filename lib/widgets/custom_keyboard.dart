import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callbacks that the keyboard invokes.
class KeyboardCallbacks {
  final VoidCallback onClear;
  final ValueChanged<String> onChar;

  const KeyboardCallbacks({required this.onClear, required this.onChar});
}

class CustomKeyboard extends StatelessWidget {
  final int layoutType; // 1-5
  final double height;
  final double textSize;
  final bool vibrationEnabled;
  final KeyboardCallbacks callbacks;

  const CustomKeyboard({
    super.key,
    required this.layoutType,
    required this.height,
    required this.textSize,
    required this.vibrationEnabled,
    required this.callbacks,
  });

  void _vibrate() {
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  double get _fontSize => textSize.clamp(18.0, 32.0);

  double _keyHeight(int totalRows) {
    // Calculate key height based on available space
    final available = height - (totalRows + 1) * 5.0 - 12.0;
    return (available / totalRows).clamp(42.0, 56.0);
  }

  // ─── Shared key builders ───

  Widget _charKey(String char, double keyH, {double flex = 1}) {
    return Expanded(
      flex: flex.toInt(),
      child: Container(
        height: keyH,
        margin: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color.fromARGB(255, 228, 84, 84),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () {
              _vibrate();
              callbacks.onChar(char);
            },
            child: Center(
              child: Text(
                char,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required String label,
    required VoidCallback onTap,
    double flex = 1,
    Color? bgColor,
    IconData? icon,
    required double keyH,
  }) {
    final color = bgColor ?? const Color(0xFFF0F0F0);
    return Expanded(
      flex: flex.toInt(),
      child: Container(
        height: keyH,
        margin: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFD0D0D0), width: 0.8),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () {
              _vibrate();
              onTap();
            },
            child: Center(
              child: icon != null
                  ? Icon(icon, size: _fontSize + 6, color: Colors.black87)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Row helper ───

  Widget _row(List<Widget> children) {
    return Row(children: children);
  }

  // ===================================================================
  // LAYOUT 1: Big 3-column number grid with QWERTY letters below
  // Style: numbers 3-col grid on top, QWERTY row at bottom
  // ===================================================================
  Widget _layout1() {
    final kH = _keyHeight(4);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Number grid: 1 2 3 / 4 5 6 / 7 8 9 / X 0 ⌫
        _row([_charKey('1', kH), _charKey('2', kH), _charKey('3', kH)]),
        _row([_charKey('4', kH), _charKey('5', kH), _charKey('6', kH)]),
        _row([_charKey('7', kH), _charKey('8', kH), _charKey('9', kH)]),
        _row([
          _actionKey(
            label: 'X',
            onTap: callbacks.onClear,
            bgColor: const Color(0xFFFFCDD2),
            keyH: kH,
            icon: Icons.close_rounded,
          ),
          _charKey('0', kH),
          _actionKey(
            label: '⌫',
            onTap: () => callbacks.onChar('⌫'),
            bgColor: const Color(0xFFFFE0B2),
            keyH: kH,
            icon: Icons.backspace_outlined,
          ),
        ]),
        const SizedBox(height: 4),
        // QWERTY letters row
        _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        _row('ASDFGHJKL'.split('').map((c) => _charKey(c, kH)).toList()),
        _row('ZXCVBNM'.split('').map((c) => _charKey(c, kH)).toList()),
      ],
    );
  }

  // ===================================================================
  // LAYOUT 2: QWERTY on top, big numbers at bottom
  // ===================================================================
  Widget _layout2() {
    final kH = _keyHeight(5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QWERTY rows
        _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        _row('ASDFGHJKL'.split('').map((c) => _charKey(c, kH)).toList()),
        _row([
          _actionKey(
            label: 'X',
            onTap: callbacks.onClear,
            bgColor: const Color(0xFFFFCDD2),
            keyH: kH,
            icon: Icons.close_rounded,
          ),
          ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
          _actionKey(
            label: '⌫',
            onTap: () => callbacks.onChar('⌫'),
            bgColor: const Color(0xFFFFE0B2),
            keyH: kH,
            icon: Icons.backspace_outlined,
          ),
        ]),
        const SizedBox(height: 4),
        // Big number rows at bottom
        _row([
          _charKey('1', kH),
          _charKey('2', kH),
          _charKey('3', kH),
          _charKey('4', kH),
          _charKey('5', kH),
        ]),
        _row([
          _charKey('6', kH),
          _charKey('7', kH),
          _charKey('8', kH),
          _charKey('9', kH),
          _charKey('0', kH),
        ]),
      ],
    );
  }

  // ===================================================================
  // LAYOUT 3: Compact full-width single row numbers, QWERTY
  // Best for small screens
  // ===================================================================
  Widget _layout3() {
    final kH = _keyHeight(5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Single number row 0-9
        _row('1234567890'.split('').map((c) => _charKey(c, kH)).toList()),
        _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        _row('ASDFGHJKL'.split('').map((c) => _charKey(c, kH)).toList()),
        _row([
          _actionKey(
            label: 'X',
            onTap: callbacks.onClear,
            bgColor: const Color(0xFFFFCDD2),
            keyH: kH,
            icon: Icons.close_rounded,
          ),
          ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
          _actionKey(
            label: '⌫',
            onTap: () => callbacks.onChar('⌫'),
            bgColor: const Color(0xFFFFE0B2),
            keyH: kH,
            icon: Icons.backspace_outlined,
          ),
        ]),
        const SizedBox(height: 2),
      ],
    );
  }

  // ===================================================================
  // LAYOUT 4: Numbers on left side, letters on right (two-panel)
  // Good for one-hand input
  // ===================================================================
  Widget _layout4() {
    final kH = _keyHeight(5);

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 3-column numpad
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _charKey('1', kH),
                    _charKey('2', kH),
                    _charKey('3', kH),
                  ],
                ),
                Row(
                  children: [
                    _charKey('4', kH),
                    _charKey('5', kH),
                    _charKey('6', kH),
                  ],
                ),
                Row(
                  children: [
                    _charKey('7', kH),
                    _charKey('8', kH),
                    _charKey('9', kH),
                  ],
                ),
                Row(
                  children: [
                    _actionKey(
                      label: 'X',
                      onTap: callbacks.onClear,
                      bgColor: const Color(0xFFFFCDD2),
                      keyH: kH,
                      icon: Icons.close_rounded,
                    ),
                    _charKey('0', kH),
                    _actionKey(
                      label: '⌫',
                      onTap: () => callbacks.onChar('⌫'),
                      bgColor: const Color(0xFFFFE0B2),
                      keyH: kH,
                      icon: Icons.backspace_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          // Right: QWERTY
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _row(
                  'QWERTY'.split('').map((c) => _charKey(c, kH)).toList(),
                ),
                _row(
                  'UIOP'.split('').map((c) => _charKey(c, kH)).toList(),
                ),
                _row('ASDFGH'.split('').map((c) => _charKey(c, kH)).toList()),
                _row('JKL'.split('').map((c) => _charKey(c, kH)).toList()),
                _row('ZXCVBNM'.split('').map((c) => _charKey(c, kH)).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // LAYOUT 5: Full-width large key keyboard, most spacious & clean
  // No CARI button. Clear/Backspace large at sides.
  // ===================================================================
  Widget _layout5() {
    final kH = _keyHeight(5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Row 1: 1-5
        _row([
          _charKey('1', kH),
          _charKey('2', kH),
          _charKey('3', kH),
          _charKey('4', kH),
          _charKey('5', kH),
        ]),
        // Row 2: 6-0
        _row([
          _charKey('6', kH),
          _charKey('7', kH),
          _charKey('8', kH),
          _charKey('9', kH),
          _charKey('0', kH),
        ]),
        // Row 3: Q-P
        _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        // Row 4: A-L with clear at start & backspace at end
        _row([
          _actionKey(
            label: 'X',
            onTap: callbacks.onClear,
            bgColor: const Color(0xFFFFCDD2),
            keyH: kH,
            icon: Icons.close_rounded,
          ),
          ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
          _actionKey(
            label: '⌫',
            onTap: () => callbacks.onChar('⌫'),
            bgColor: const Color(0xFFFFE0B2),
            keyH: kH,
            icon: Icons.backspace_outlined,
          ),
        ]),
        // Row 5: Z-M + space
        _row([
          _actionKey(
            label: '',
            onTap: () => callbacks.onChar(' '),
            bgColor: Colors.white,
            keyH: kH,
            icon: Icons.space_bar,
          ),
          ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        ]),
      ],
    );
  }

  // ─── Build layout based on type ───
  Widget _buildLayout() {
    switch (layoutType) {
      case 1:
        return _layout1();
      case 2:
        return _layout2();
      case 3:
        return _layout3();
      case 4:
        return _layout4();
      case 5:
        return _layout5();
      default:
        return _layout1();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: _buildLayout(),
    );
  }
}
