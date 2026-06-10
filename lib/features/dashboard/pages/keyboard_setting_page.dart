import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/keyboard_setting_service.dart';

class KeyboardSettingPage extends StatefulWidget {
  const KeyboardSettingPage({super.key});

  @override
  State<KeyboardSettingPage> createState() => _KeyboardSettingPageState();
}

class _KeyboardSettingPageState extends State<KeyboardSettingPage> {
  int _selectedType = 0;
  double _height = 280;
  double _textSize = 20;
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
    setState(() {
      _selectedType = type;
      _height = height;
      _textSize = textSize;
      _vibration = vibration;
      _keepScreenOn = keepScreenOn;
    });
  }

  Future<void> _saveType(int type) async {
    await KeyboardSettingService.setKeyboardType(type);
    setState(() => _selectedType = type);
  }

  Future<void> _saveHeight(double h) async {
    await KeyboardSettingService.setKeyboardHeight(h);
    setState(() => _height = h);
  }

  Future<void> _saveTextSize(double s) async {
    await KeyboardSettingService.setTextSize(s);
    setState(() => _textSize = s);
  }

  Future<void> _saveVibration(bool v) async {
    await KeyboardSettingService.setVibrationEnabled(v);
    setState(() => _vibration = v);
  }

  Future<void> _saveKeepScreenOn(bool k) async {
    await KeyboardSettingService.setKeepScreenOn(k);
    setState(() => _keepScreenOn = k);
    if (k) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setting Keyboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Keyboard type ---
          const Text(
            "Jenis Keyboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Option 0: System
          _buildTypeTile(
            title: "Keyboard Bawaan",
            subtitle: "Gunakan keyboard bawaan HP",
            value: 0,
            icon: Icons.phone_android,
          ),
          const SizedBox(height: 4),

          // Option 1: Big numbers on top
          _buildTypeTile(
            title: "Keyboard 1 - Angka Besar Grid 3 Kolom",
            subtitle: "Numpad 3 kolom di atas, QWERTY di bawah",
            value: 1,
            icon: Icons.dialpad,
          ),
          const SizedBox(height: 4),

          // Option 2: QWERTY on top
          _buildTypeTile(
            title: "Keyboard 2 - Huruf Atas, Angka Bawah",
            subtitle: "QWERTY di atas, 2 baris angka besar di bawah",
            value: 2,
            icon: Icons.keyboard_alt_outlined,
          ),
          const SizedBox(height: 4),

          // Option 3: Single row numbers
          _buildTypeTile(
            title: "Keyboard 3 - Compact Full Width",
            subtitle: "1 baris angka, QWERTY, spasi — cocok layar kecil",
            value: 3,
            icon: Icons.keyboard,
          ),
          const SizedBox(height: 4),

          // Option 4: Calculator + letters
          _buildTypeTile(
            title: "Keyboard 4 - Angka Kiri, Huruf Kanan",
            subtitle: "Numpad 3 kolom di kiri + QWERTY di kanan",
            value: 4,
            icon: Icons.calculate,
          ),
          const SizedBox(height: 4),

          // Option 5: Full width large
          _buildTypeTile(
            title: "Keyboard 5 - Full Width Besar",
            subtitle: "Tombol huruf/angka besar, full width, rapi",
            value: 5,
            icon: Icons.space_bar,
          ),

          const Divider(height: 40),

          // --- Height slider ---
          const Text(
            "Tinggi Keyboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _height,
            min: 180,
            max: 420,
            divisions: 24,
            label: "${_height.round()} px",
            onChanged: (v) => setState(() => _height = v),
            onChangeEnd: _saveHeight,
          ),
          Center(
            child: Text(
              "${_height.round()} pixel",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),

          // --- Text size slider ---
          const Text(
            "Ukuran Teks Pencarian / Keyboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _textSize,
            min: 16,
            max: 32,
            divisions: 16,
            label: "${_textSize.toStringAsFixed(0)} sp",
            onChanged: (v) => setState(() => _textSize = v),
            onChangeEnd: _saveTextSize,
          ),
          Center(
            child: Text(
              "${_textSize.toStringAsFixed(0)} sp",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),

          // --- Vibration toggle ---
          SwitchListTile(
            title: const Text("Getar"),
            subtitle: const Text("Getaran pendek setiap tekan tombol"),
            value: _vibration,
            onChanged: _saveVibration,
          ),

          // --- Keep screen on toggle ---
          SwitchListTile(
            title: const Text("Layar Selalu Menyala"),
            subtitle: const Text("Mencegah layar mati saat aplikasi terbuka"),
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
    return Card(
      color: selected ? Colors.purple.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.purple : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.purple : Colors.grey),
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
