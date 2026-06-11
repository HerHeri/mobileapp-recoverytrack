import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callbacks that the keyboard invokes.
class KeyboardCallbacks {
  final VoidCallback onClear;
  final ValueChanged<String> onChar;

  const KeyboardCallbacks({required this.onClear, required this.onChar});
}

class CustomKeyboard extends StatelessWidget {
  /// 1 - 5. Use 0 outside this widget for keyboard bawaan HP.
  final int layoutType;

  /// Total keyboard frame height from setting page.
  /// This widget will always scale rows to this height to prevent overflow.
  final double height;

  /// Requested text size from setting page.
  /// Real font size is auto-limited by key height to prevent overflow.
  final double textSize;

  final bool vibrationEnabled;
  final KeyboardCallbacks callbacks;
  final Color? keyboardBackground;
  final Color? keyBackground;
  final Color? actionKeyBackground;
  final Color? keyBorder;
  final Color? keyForeground;

  const CustomKeyboard({
    super.key,
    required this.layoutType,
    required this.height,
    required this.textSize,
    required this.vibrationEnabled,
    required this.callbacks,
    this.keyboardBackground,
    this.keyBackground,
    this.actionKeyBackground,
    this.keyBorder,
    this.keyForeground,
  });

  Color get _keyboardBg => keyboardBackground ?? const Color(0xFFE6F6FB);
  Color get _keyBg => keyBackground ?? const Color(0xFFCDECF6);
  Color get _keyBgAlt => actionKeyBackground ?? const Color(0xFF9FD9EC);
  Color get _keyBorder => keyBorder ?? const Color(0xFF58B2D2);
  Color get _textColor => keyForeground ?? const Color(0xFF06384D);

  static const double _gap = 1.0;
  static const double _radius = 8.0;

  void _vibrate() {
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  double _safeFontSize(double keyHeight) {
    // Keep font inside the key even when user sets textSize too large.
    final requested = textSize.clamp(18.0, 46.0);
    return math.min(requested, keyHeight * 0.58).clamp(16.0, 46.0);
  }

  double _safeIconSize(double keyHeight) {
    return math.min(_safeFontSize(keyHeight) + 8, keyHeight * 0.66);
  }

  double _keyHeight(double maxHeight, int rowCount) {
    // The old code used a fixed clamp, so several layouts overflowed when the
    // number of visible rows was more than the value used in _keyHeight().
    // This version calculates from the real row count.
    final safeMaxHeight = math.max(80.0, maxHeight);
    final totalGap = (rowCount - 1) * _gap;
    final available = safeMaxHeight - totalGap;
    return math.max(18.0, available / rowCount);
  }

  Widget _charKey(String char, double keyH, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: keyH,
        child: Padding(
          padding: const EdgeInsets.all(0.7),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _keyBg,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _keyBorder, width: 0.7),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(_radius),
                onTap: () {
                  _vibrate();
                  callbacks.onChar(char);
                },
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      char,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _safeFontSize(keyH),
                        fontWeight: FontWeight.w900,
                        color: _textColor,
                        height: 1.0,
                        letterSpacing: 0.3,
                        shadows: const [
                          Shadow(
                            color: Color(0x55000000),
                            offset: Offset(0.8, 1.0),
                            blurRadius: 1.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required VoidCallback onTap,
    required double keyH,
    required IconData icon,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: keyH,
        child: Padding(
          padding: const EdgeInsets.all(0.7),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _keyBgAlt,
              borderRadius: BorderRadius.circular(_radius + 6),
              border: Border.all(color: _keyBorder, width: 0.8),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_radius + 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(_radius + 6),
                onTap: () {
                  _vibrate();
                  onTap();
                },
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(
                      icon,
                      size: _safeIconSize(keyH),
                      color: _textColor,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          offset: Offset(0.8, 1.0),
                          blurRadius: 1.2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _clearKey(double keyH, {int flex = 1}) {
    return _actionKey(
      onTap: callbacks.onClear,
      keyH: keyH,
      icon: Icons.cancel_outlined,
      flex: flex,
    );
  }

  Widget _backspaceKey(double keyH, {int flex = 1}) {
    return _actionKey(
      onTap: () => callbacks.onChar('⌫'),
      keyH: keyH,
      icon: Icons.backspace_outlined,
      flex: flex,
    );
  }

  Widget _ghost(double keyH, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: SizedBox(height: keyH),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  List<Widget> _withGaps(List<Widget> rows) {
    final widgets = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      widgets.add(rows[i]);
      if (i != rows.length - 1) widgets.add(const SizedBox(height: _gap));
    }
    return widgets;
  }

  Widget _column(List<Widget> rows) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: _withGaps(rows),
    );
  }

  // ===================================================================
  // LAYOUT 1: Full width compact. Angka satu baris, huruf di bawah.
  // Paling aman untuk menghilangkan space kiri-kanan dan mencegah overflow.
  // ===================================================================
  Widget _layout1(double maxH) {
    const rowCount = 4;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _row('1234567890'.split('').map((c) => _charKey(c, kH)).toList()),
      _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _row([
        _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH),
      ]),
      _row([
        _clearKey(kH, flex: 1),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _backspaceKey(kH, flex: 1),
      ]),
    ]);
  }

  // ===================================================================
  // LAYOUT 2: Seperti contoh: numpad besar di atas, QWERTY di bawah.
  // Clear kiri dan backspace kanan dibuat besar.
  // ===================================================================
  Widget _layout2(double maxH) {
    const rowCount = 6;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _row([
        _clearKey(kH, flex: 2),
        _charKey('1', kH),
        _charKey('2', kH),
        _charKey('3', kH),
        _backspaceKey(kH, flex: 2),
      ]),
      _row([
        _ghost(kH, flex: 2),
        _charKey('4', kH),
        _charKey('5', kH),
        _charKey('6', kH),
        _ghost(kH, flex: 2),
      ]),
      _row([
        _charKey('0', kH, flex: 2),
        _charKey('7', kH),
        _charKey('8', kH),
        _charKey('9', kH),
        _charKey('0', kH, flex: 2),
      ]),
      _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _row([
        _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH),
      ]),
      _row([
        _clearKey(kH, flex: 1),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _backspaceKey(kH, flex: 1),
      ]),
    ]);
  }

  // ===================================================================
  // LAYOUT 3: Angka satu baris + QWERTY besar. Cocok layar kecil.
  // ===================================================================
  Widget _layout3(double maxH) {
    const rowCount = 5;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _row('12345'.split('').map((c) => _charKey(c, kH)).toList()),
      _row('67890'.split('').map((c) => _charKey(c, kH)).toList()),
      _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _row([
        _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH),
      ]),
      _row([
        _clearKey(kH, flex: 1),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _backspaceKey(kH, flex: 1),
      ]),
    ]);
  }

  // ===================================================================
  // LAYOUT 4: Huruf di atas, angka grid besar di bawah.
  // ===================================================================
  Widget _layout4(double maxH) {
    const rowCount = 6;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _row([
        _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH),
      ]),
      _row([
        _ghost(kH, flex: 2),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH, flex: 2),
      ]),
      _row([
        _clearKey(kH, flex: 2),
        _charKey('1', kH),
        _charKey('2', kH),
        _charKey('3', kH),
        _backspaceKey(kH, flex: 2),
      ]),
      _row([
        _ghost(kH, flex: 2),
        _charKey('4', kH),
        _charKey('5', kH),
        _charKey('6', kH),
        _ghost(kH, flex: 2),
      ]),
      _row([
        _charKey('0', kH, flex: 2),
        _charKey('7', kH),
        _charKey('8', kH),
        _charKey('9', kH),
        _charKey('0', kH, flex: 2),
      ]),
    ]);
  }

  // ===================================================================
  // LAYOUT 5: Angka grid tanpa tombol kiri, backspace kanan besar.
  // ===================================================================
  Widget _layout5(double maxH) {
    const rowCount = 6;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _row([
        _charKey('1', kH),
        _charKey('2', kH),
        _charKey('3', kH),
        _backspaceKey(kH, flex: 2),
      ]),
      _row([
        _charKey('4', kH),
        _charKey('5', kH),
        _charKey('6', kH),
        _charKey('0', kH, flex: 2),
      ]),
      _row([
        _charKey('7', kH),
        _charKey('8', kH),
        _charKey('9', kH),
        _clearKey(kH, flex: 2),
      ]),
      _row('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _row([
        _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        _ghost(kH),
      ]),
      _row([
        _clearKey(kH, flex: 1),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _backspaceKey(kH, flex: 1),
      ]),
    ]);
  }

  Widget _buildLayout(double maxH) {
    switch (layoutType) {
      case 1:
        return _layout1(maxH);
      case 2:
        return _layout2(maxH);
      case 3:
        return _layout3(maxH);
      case 4:
        return _layout4(maxH);
      case 5:
        return _layout5(maxH);
      default:
        return _layout1(maxH);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeHeight = height.clamp(120.0, 420.0);

    return SizedBox(
      width: double.infinity,
      height: safeHeight,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(color: _keyboardBg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : safeHeight;

              return SizedBox.expand(child: _buildLayout(maxH));
            },
          ),
        ),
      ),
    );
  }
}
