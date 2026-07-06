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

  static const double _gap = 0.4;
  static const double _radius = 6.0;

  void _vibrate() {
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  double _safeFontSize(double keyHeight) {
    return math.min(textSize.clamp(18.0, 40.0), keyHeight * 0.75);
  }

  double _safeIconSize(double keyHeight) {
    return math.min(keyHeight * 0.42, 28.0);
  }

  double _keyHeight(double maxHeight, int rowCount) {
    final available = maxHeight - ((rowCount - 1) * _gap);
    return available / rowCount;
  }

  Widget _indentRow(
    List<Widget> children, {
    double left = 0,
    double right = 0,
  }) {
    return Row(
      children: [
        SizedBox(width: left),
        Expanded(child: Row(children: children)),
        SizedBox(width: right),
      ],
    );
  }

  // Widget _charKey(String char, double keyH, {int flex = 1}) {
  //   return Expanded(
  //     flex: flex,
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.3),
  //       decoration: BoxDecoration(
  //         color: _keyBg,
  //         borderRadius: BorderRadius.circular(math.min(_radius, keyH * 0.22)),
  //         border: Border.all(color: _keyBorder, width: .3),
  //       ),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(math.min(12, keyH * 0.22)),
  //           onTap: () {
  //             _vibrate();
  //             callbacks.onChar(char);
  //           },
  //           child: FittedBox(
  //             fit: BoxFit.scaleDown,
  //             child: Text(
  //               char,
  //               maxLines: 1,
  //               style: TextStyle(
  //                 fontWeight: FontWeight.w700,
  //                 fontSize: _safeFontSize(keyH),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _charKey(String char, double keyH, {int flex = 1, double? height}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: height ?? keyH,
          child: Container(
            height: height ?? keyH,
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.3),
            decoration: BoxDecoration(
              color: _keyBg,
              borderRadius: BorderRadius.circular(
                math.min(_radius, keyH * 0.22),
              ),
              border: Border.all(color: _keyBorder, width: .3),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(math.min(12, keyH * 0.22)),
                onTap: () {
                  _vibrate();
                  callbacks.onChar(char);
                },
                child: Center(
                  child: Text(
                    char,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: _safeFontSize(keyH),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _keyBgAlt,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _keyBorder, width: .3),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(_radius),
                onTap: () {
                  _vibrate();
                  onTap();
                },
                child: SizedBox.expand(
                  child: Center(
                    child: Icon(
                      icon,
                      size: _safeIconSize(keyH),
                      color: _textColor,
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

  List<Widget> _withGaps(List<Widget> rows) {
    final widgets = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      widgets.add(rows[i]);
      if (i != rows.length - 1) widgets.add(const SizedBox(height: _gap));
    }
    return widgets;
  }

  Widget _column(List<Widget> rows, double rowHeight, {double rowGap = 1}) {
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          SizedBox(height: rowHeight, child: rows[i]),
          if (i < rows.length - 1) SizedBox(height: rowGap),
        ],
      ],
    );
  }

  // ===================================================================
  // LAYOUT 1: Full width compact. Angka satu baris, huruf di bawah.
  // Paling aman untuk menghilangkan space kiri-kanan dan mencegah overflow.
  // ===================================================================
  Widget _layout1(double maxH) {
    const rowCount = 4;
    final kH = _keyHeight(maxH, rowCount) - 3;

    return _column(
      [
        _indentRow('1234567890'.split('').map((c) => _charKey(c, kH)).toList()),
        _indentRow('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        _indentRow([
          // _ghost(kH),
          ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
          // _ghost(kH),
        ]),
        _indentRow([
          _clearKey(kH, flex: 1),
          ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
          _backspaceKey(kH, flex: 1),
        ]),
      ],
      73,
      rowGap: 0,
    );
  }

  // ===================================================================
  // LAYOUT 2: Seperti contoh: numpad besar di atas, QWERTY di bawah.
  // Clear kiri dan backspace kanan dibuat besar.
  // ===================================================================
  Widget _layout2(double maxH) {
    const rowCount = 7;
    final kH = _keyHeight(maxH, rowCount) + 4;

    return _column(
      [
        _indentRow([_charKey('1', kH), _charKey('2', kH), _charKey('3', kH)]),

        _indentRow(
          [_charKey('4', kH), _charKey('5', kH), _charKey('6', kH)],
          left: 0,
          right: 0,
        ),

        _indentRow(
          [_charKey('7', kH), _charKey('8', kH), _charKey('9', kH)],
          left: 0,
          right: 0,
        ),

        _indentRow(
          [_clearKey(kH), _charKey('0', kH), _backspaceKey(kH)],
          left: 0,
          right: 0,
        ),

        _indentRow('QWERTYUIOP'.split('').map((e) => _charKey(e, kH)).toList()),

        _indentRow(
          'ASDFGHJKL'.split('').map((e) => _charKey(e, kH)).toList(),
          left: 0,
          right: 0,
        ),

        _indentRow(
          [
            _clearKey(kH),
            ...'ZXCVBNM'.split('').map((e) => _charKey(e, kH)),
            _backspaceKey(kH),
          ],
          left: 0,
          right: 0,
        ),
      ],
      40,
      rowGap: 2,
    );
  }

  // ===================================================================
  // LAYOUT 3: Angka satu baris + QWERTY besar. Cocok layar kecil.
  // ===================================================================
  Widget _layout3(double maxH) {
    const rowCount = 5;
    final kH = _keyHeight(maxH, rowCount) - 5;

    return _column(
      [
        _indentRow('12345'.split('').map((c) => _charKey(c, kH)).toList()),
        _indentRow('67890'.split('').map((c) => _charKey(c, kH)).toList()),
        _indentRow('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
        _indentRow([
          // _ghost(kH),
          ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
          // _ghost(kH),
        ]),
        _indentRow([
          _clearKey(kH, flex: 1),
          ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
          _backspaceKey(kH, flex: 1),
        ]),
      ],
      57,
      rowGap: 1,
    );
  }

  // ===================================================================
  // LAYOUT 4: Huruf di atas, angka grid besar di bawah.
  // ===================================================================
  Widget _layout4(double maxH) {
    const rowCount = 6;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _indentRow('QWERTYUIOP'.split('').map((e) => _charKey(e, kH)).toList()),

      _indentRow(
        'ASDFGHJKL'.split('').map((e) => _charKey(e, kH)).toList(),
        left: 0,
        right: 0,
      ),

      _indentRow(
        [
          _clearKey(kH),
          ...'ZXCVBNM'.split('').map((e) => _charKey(e, kH)),
          _backspaceKey(kH),
        ],
        left: 0,
        right: 0,
      ),

      _indentRow([
        _charKey('1', kH),
        _charKey('2', kH),
        _charKey('3', kH),
        _charKey('4', kH),
        _charKey('5', kH),
      ]),

      _indentRow([
        _charKey('6', kH),
        _charKey('7', kH),
        _charKey('8', kH),
        _charKey('9', kH),
        _charKey('0', kH),
      ]),

      _indentRow([
        _clearKey(kH, flex: 2),
        _charKey('.', kH),
        _charKey('-', kH),
        _backspaceKey(kH, flex: 2),
      ]),
    ], 48);
  }

  // ===================================================================
  // LAYOUT 5: Angka grid tanpa tombol kiri, backspace kanan besar.
  // ===================================================================
  Widget _layout5(double maxH) {
    const rowCount = 6;
    final kH = _keyHeight(maxH, rowCount);

    return _column([
      _indentRow([
        _charKey('1', kH),
        _charKey('2', kH),
        _charKey('3', kH),
        _backspaceKey(kH, flex: 2),
      ]),
      _indentRow([
        _charKey('4', kH),
        _charKey('5', kH),
        _charKey('6', kH),
        _charKey('0', kH, flex: 2),
      ]),
      _indentRow([
        _charKey('7', kH),
        _charKey('8', kH),
        _charKey('9', kH),
        _clearKey(kH, flex: 2),
      ]),
      _indentRow('QWERTYUIOP'.split('').map((c) => _charKey(c, kH)).toList()),
      _indentRow([
        // _ghost(kH),
        ...'ASDFGHJKL'.split('').map((c) => _charKey(c, kH)),
        // _ghost(kH),
      ]),
      _indentRow([
        _clearKey(kH, flex: 1),
        ...'ZXCVBNM'.split('').map((c) => _charKey(c, kH)),
        _backspaceKey(kH, flex: 1),
      ]),
    ], 48);
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
    final maxHeight = MediaQuery.of(context).size.height * 0.38;

    final safeHeight = math.min(height, maxHeight);

    final rowCount = switch (layoutType) {
      2 => 7,
      4 => 6,
      5 => 6,
      3 => 5,
      _ => 4,
    };

    return SizedBox(
      width: double.infinity,
      height: safeHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: _keyboardBg),
        child: _buildLayout(safeHeight),
      ),
    );
  }
}
