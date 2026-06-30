import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/keyboard_setting_service.dart';

class KeyboardSettingPage extends StatefulWidget {
  const KeyboardSettingPage({super.key});

  @override
  State<KeyboardSettingPage> createState() => _KeyboardSettingPageState();
}

class _KeyboardSettingPageState extends State<KeyboardSettingPage> {
  int _selectedType = 1;
  double _height = 270;
  double _textSize = 34;
  bool _vibration = true;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final type = await KeyboardSettingService.getKeyboardType();
    final height = await KeyboardSettingService.getKeyboardHeight();
    final textSize = await KeyboardSettingService.getTextSize();
    final vibration = await KeyboardSettingService.getVibrationEnabled();
    final keepScreenOn = await KeyboardSettingService.getKeepScreenOn();

    if (!mounted) return;
    setState(() {
      _selectedType = type;
      _height = height.clamp(190.0, 340.0);
      _textSize = textSize.clamp(20.0, 72.0);
      _vibration = vibration;
      _keepScreenOn = keepScreenOn;
    });
  }

  Future<void> _saveType(int type) async {
    await KeyboardSettingService.setKeyboardType(type);
    if (!mounted) return;
    setState(() => _selectedType = type);
  }

  Future<void> _saveHeight(double h) async {
    final safe = h.clamp(190.0, 340.0);
    await KeyboardSettingService.setKeyboardHeight(safe);
    if (!mounted) return;
    setState(() => _height = safe);
  }

  Future<void> _saveTextSize(double s) async {
    final safe = s.clamp(20.0, 72.0);
    await KeyboardSettingService.setTextSize(safe);
    if (!mounted) return;
    setState(() => _textSize = safe);
  }

  Future<void> _saveVibration(bool v) async {
    await KeyboardSettingService.setVibrationEnabled(v);
    if (!mounted) return;
    setState(() => _vibration = v);
  }

  Future<void> _saveKeepScreenOn(bool k) async {
    await KeyboardSettingService.setKeepScreenOn(k);
    if (k) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    if (!mounted) return;
    setState(() => _keepScreenOn = k);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Setting Keyboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Jenis Keyboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          _buildTypeTile(
            title: 'Keyboard Bawaan',
            subtitle: 'Gunakan keyboard bawaan HP',
            value: 0,
            icon: Icons.phone_android,
          ),
          const SizedBox(height: 4),

          _buildTypeTile(
            title: 'Keyboard 1 - Full Width Compact',
            // subtitle: 'Angka 1 baris + QWERTY, paling aman tanpa overflow',
            subtitle: '',
            value: 1,
            icon: Icons.keyboard,
          ),
          const SizedBox(height: 4),

          _buildTypeTile(
            title: 'Keyboard 2 - Numpad Besar Atas',
            // subtitle: 'Clear kiri, angka tengah, backspace kanan, QWERTY bawah',
            subtitle: '',
            value: 2,
            icon: Icons.dialpad,
          ),
          const SizedBox(height: 4),

          _buildTypeTile(
            title: 'Keyboard 3 - Full Width Cepat',
            // subtitle: 'Angka dan huruf lebar penuh untuk layar kecil',
            subtitle: '',
            value: 3,
            icon: Icons.keyboard_alt_outlined,
          ),
          const SizedBox(height: 4),

          _buildTypeTile(
            title: 'Keyboard 4 - Huruf Atas Angka Bawah',
            // subtitle: 'QWERTY di atas, angka grid di bawah',
            subtitle: '',
            value: 4,
            icon: Icons.space_bar,
          ),
          const SizedBox(height: 4),

          _buildTypeTile(
            title: 'Keyboard 5 - Backspace Kanan Besar',
            // subtitle: 'Cocok untuk hapus cepat saat input nomor polisi',
            subtitle: '',
            value: 5,
            icon: Icons.backspace_outlined,
          ),

          const Divider(height: 40),

          const Text(
            'Tinggi Keyboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _height,
            min: 300,
            max: 340,
            divisions: 15,
            label: '${_height.round()} px',
            onChanged: (v) => setState(() => _height = v),
            onChangeEnd: _saveHeight,
          ),
          Center(
            child: Text(
              '${_height.round()} pixel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Ukuran Huruf Keyboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _textSize,
            min: 32,
            max: 72,
            divisions: 22,
            label: '${_textSize.toStringAsFixed(0)} sp',
            onChanged: (v) => setState(() => _textSize = v),
            onChangeEnd: _saveTextSize,
          ),
          Center(
            child: Text(
              '${_textSize.toStringAsFixed(0)} sp',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Getar'),
            subtitle: const Text('Getaran pendek setiap tekan tombol'),
            value: _vibration,
            onChanged: _saveVibration,
          ),

          SwitchListTile(
            title: const Text('Layar Selalu Menyala'),
            subtitle: const Text('Mencegah layar mati saat aplikasi terbuka'),
            value: _keepScreenOn,
            onChanged: _saveKeepScreenOn,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTile({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
  }) {
    final bool selected = _selectedType == value;
    final theme = Theme.of(context);

    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Radio<int>(
          value: value,
          groupValue: _selectedType,
          onChanged: (v) {
            if (v != null) _saveType(v);
          },
        ),
        onTap: () => _saveType(value),
      ),
    );
  }
}
