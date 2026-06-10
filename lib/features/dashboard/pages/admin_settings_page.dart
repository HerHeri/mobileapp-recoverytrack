import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // SMTP Controllers
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smtpUserController = TextEditingController();
  final _smtpPassController = TextEditingController();
  final _smtpFromController = TextEditingController();

  // Telegram Controllers
  final _tgBotTokenController = TextEditingController();
  final _tgChatIdController = TextEditingController();

  // SMTP Provider state
  String? _selectedProvider;
  bool _obscureSmtpPass = true;
  final List<Map<String, String>> _smtpProviders = [
    {'name': 'Gmail', 'host': 'smtp.gmail.com', 'port': '587'},
    {'name': 'Outlook', 'host': 'smtp.office365.com', 'port': '587'},
    {'name': 'Yahoo', 'host': 'smtp.mail.yahoo.com', 'port': '465'},
    {'name': 'Zoho', 'host': 'smtp.zoho.com', 'port': '465'},
    {'name': 'Custom', 'host': '', 'port': ''},
  ];

  // Additional Gmail hosts for detection
  final List<String> _gmailHosts = ['smtp.gmail.com', 'smtp.googlemail.com'];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPassController.dispose();
    _smtpFromController.dispose();
    _tgBotTokenController.dispose();
    _tgChatIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await SettingsService.getAdminSettings();
      final emailServer = data['email_server'] ?? {};
      final telegramBot = data['telegram_bot'] ?? {};

      setState(() {
        _smtpHostController.text = emailServer['host'] ?? "";
        _smtpPortController.text = emailServer['port']?.toString() ?? "";
        _smtpUserController.text = emailServer['username'] ?? "";
        _smtpPassController.text = emailServer['password'] ?? "";
        _smtpFromController.text = emailServer['name_email'] ?? "";
        _tgBotTokenController.text = telegramBot['token'] ?? "";
        _tgChatIdController.text = telegramBot['group_id'] ?? "";

        // Detect provider
        final host = emailServer['host'] ?? "";
        String? detectedName;
        if (_gmailHosts.contains(host)) {
          detectedName = 'Gmail';
        } else {
          final provider = _smtpProviders.firstWhere(
            (p) => p['host'] == host && p['name'] != 'Custom',
            orElse: () => _smtpProviders.last, // Custom
          );
          detectedName = provider['name'];
        }
        _selectedProvider = detectedName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final body = {
      "host": _smtpHostController.text,
      "port": int.tryParse(_smtpPortController.text) ?? 587,
      "username": _smtpUserController.text,
      "password": _smtpPassController.text,
      "name_email": _smtpFromController.text,
      "token": _tgBotTokenController.text,
      "group_id": _tgChatIdController.text,
    };

    try {
      final response = await SettingsService.updateAdminSettings(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Pengaturan berhasil disimpan",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Admin"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff667eea), Color(0xff764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _buildFormView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchSettings,
            child: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Pengaturan SMTP (Email)"),
            _buildSectionCard([
              DropdownButtonFormField<String>(
                initialValue: _selectedProvider,
                decoration: InputDecoration(
                  labelText: "Provider SMTP",
                  prefixIcon: const Icon(Icons.mail_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _smtpProviders.map((p) {
                  return DropdownMenuItem(
                    value: p['name'],
                    child: Text(p['name']!),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProvider = val;
                    final provider = _smtpProviders.firstWhere(
                      (p) => p['name'] == val,
                    );
                    if (val != "Custom") {
                      _smtpHostController.text = provider['host']!;
                      _smtpPortController.text = provider['port']!;
                    }
                  });
                },
              ),
              _buildTextField(
                _smtpHostController,
                "SMTP Host",
                Icons.dns_outlined,
                readOnly: _selectedProvider != "Custom",
              ),
              _buildTextField(
                _smtpPortController,
                "SMTP Port",
                Icons.numbers,
                isNumber: true,
                readOnly: _selectedProvider != "Custom",
              ),
              _buildTextField(
                _smtpUserController,
                "SMTP Username",
                Icons.person_outline,
              ),
              _buildTextField(
                _smtpPassController,
                "SMTP Password",
                Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureSmtpPass,
                onToggleObscure: () =>
                    setState(() => _obscureSmtpPass = !_obscureSmtpPass),
              ),
              _buildTextField(
                _smtpFromController,
                "Email Pengirim",
                Icons.email_outlined,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionTitle("Pengaturan Telegram"),
            _buildSectionCard([
              _buildTextField(
                _tgBotTokenController,
                "Bot Token Telegram",
                Icons.smart_toy_outlined,
              ),
              _buildTextField(
                _tgChatIdController,
                "Chat/Group ID Telegram",
                Icons.chat_bubble_outline,
              ),
            ]),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff764ba2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Simpan Pengaturan"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPassword = false,
    bool readOnly = false,
    bool? obscureText,
    VoidCallback? onToggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      obscureText: obscureText ?? isPassword,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText == false
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => v!.isEmpty ? "$label wajib diisi" : null,
    );
  }
}
