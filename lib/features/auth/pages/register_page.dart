import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/auth_service.dart';
import 'document_camera_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const int _maxFileSize = 2 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _alamatController = TextEditingController();
  final _domisiliController = TextEditingController();

  XFile? _ktpPhoto;
  XFile? _selfieKtpPhoto;
  XFile? _suratTugasPhoto;
  bool _submitting = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _alamatController.dispose();
    _domisiliController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(
    DocumentCaptureType type,
    ValueChanged<XFile> onSelected,
  ) async {
    try {
      final photo = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (_) => DocumentCameraPage(type: type)),
      );
      if (photo == null) return;

      if (await photo.length() > _maxFileSize) {
        _showMessage('Ukuran foto maksimal 2 MB. Silakan ambil ulang foto.');
        return;
      }

      if (mounted) {
        setState(() => onSelected(photo));
      }
    } catch (e) {
      _showMessage(
        'Kamera tidak dapat dibuka. Pastikan izin kamera sudah diberikan.',
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_ktpPhoto == null ||
        _selfieKtpPhoto == null ||
        _suratTugasPhoto == null) {
      _showMessage('Semua dokumen foto wajib diambil.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        nik: _nikController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
        alamat: _alamatController.text.trim(),
        domisili: _domisiliController.text.trim(),
        ktpPhoto: _ktpPhoto!,
        selfieKtpPhoto: _selfieKtpPhoto!,
        suratTugasPhoto: _suratTugasPhoto!,
      );

      if (!mounted) return;
      await _showResultAlert(
        success: true,
        title: 'Registrasi berhasil',
        message:
            response['message'] ??
            'Akun Anda sedang menunggu verifikasi Admin.',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        await _showResultAlert(
          success: false,
          title: 'Registrasi gagal',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _showResultAlert({
    required bool success,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: success
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: success
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            size: 30,
          ),
        ),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(success ? 'Kembali ke Login' : 'Periksa Kembali'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: theme.brightness == Brightness.light
              ? const LinearGradient(
                  colors: [Color(0xFFF1F5FF), Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const _RegisterHeader(),
              const SizedBox(height: 16),
              _StepIndicator(currentStep: _currentStep),
              const SizedBox(height: 16),
              if (_currentStep == 0)
                _FormSection(
                  number: '1',
                  title: 'Profil & Informasi Dasar',
                  icon: Icons.badge_outlined,
                  children: [
                    _field(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hint: 'Nama lengkap sesuai identitas',
                      icon: Icons.person_outline_rounded,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hint: 'email@domain.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        final email = value!.trim();
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _phoneController,
                      label: 'Nomor Telepon/WhatsApp',
                      hint: 'Contoh: 628xxxxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        final length = value!.trim().length;
                        if (length < 7 || length > 15) {
                          return 'Nomor telepon harus 7-15 digit';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _nikController,
                      label: 'Nomor Induk Kependudukan (NIK)',
                      hint: '16 digit NIK KTP',
                      icon: Icons.fingerprint_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        if (value!.trim().length != 16) {
                          return 'NIK harus tepat 16 digit';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      hint: 'Minimal 6 karakter',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _hidePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        if (value!.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _confirmationController,
                      label: 'Konfirmasi Kata Sandi',
                      hint: 'Ketik ulang kata sandi',
                      icon: Icons.lock_reset_rounded,
                      obscureText: _hideConfirmation,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _hideConfirmation = !_hideConfirmation,
                          );
                        },
                        icon: Icon(
                          _hideConfirmation
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        if (value != _passwordController.text) {
                          return 'Konfirmasi kata sandi tidak sama';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _field(
                      controller: _alamatController,
                      label: 'Alamat Sesuai KTP/STNK',
                      hint: 'Tulis alamat lengkap sesuai identitas',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: _required,
                      textInputAction: TextInputAction.newline,
                    ),
                    _field(
                      controller: _domisiliController,
                      label: 'Alamat Domisili Sekarang',
                      hint: 'Tulis alamat domisili aktif',
                      icon: Icons.home_work_outlined,
                      maxLines: 3,
                      validator: _required,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              if (_currentStep == 1)
                _FormSection(
                  number: '2',
                  title: 'Dokumen Verifikasi Fisik',
                  icon: Icons.shield_outlined,
                  children: [
                    _PhotoField(
                      title: 'Foto KTP',
                      subtitle: 'Ambil foto KTP secara langsung',
                      icon: Icons.credit_card_rounded,
                      file: _ktpPhoto,
                      onTap: () => _takePhoto(
                        DocumentCaptureType.ktp,
                        (photo) => _ktpPhoto = photo,
                      ),
                    ),
                    _PhotoField(
                      title: 'Selfie dengan KTP',
                      subtitle: 'Pastikan wajah dan KTP terlihat jelas',
                      icon: Icons.person_pin_circle_outlined,
                      file: _selfieKtpPhoto,
                      onTap: () => _takePhoto(
                        DocumentCaptureType.selfieKtp,
                        (photo) => _selfieKtpPhoto = photo,
                      ),
                    ),
                    _PhotoField(
                      title: 'Foto Surat Tugas',
                      subtitle: 'Ambil foto surat tugas secara langsung',
                      icon: Icons.description_outlined,
                      file: _suratTugasPhoto,
                      onTap: () => _takePhoto(
                        DocumentCaptureType.suratTugas,
                        (photo) => _suratTugasPhoto = photo,
                      ),
                    ),
                    Text(
                      'Format JPG/PNG, maksimal 2 MB per foto.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (_currentStep == 0)
                FilledButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Lanjut ke Verifikasi'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shield_outlined),
                  label: Text(
                    _submitting
                        ? 'Mengirim Pendaftaran...'
                        : 'Ajukan Pendaftaran',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _currentStep = 0),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Kembali ke Data Profil'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        maxLength: maxLength,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Akun Recovery Track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi data dan dokumen untuk proses verifikasi Admin.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StepItem(
              number: '1',
              label: 'Data Profil',
              active: currentStep == 0,
              completed: currentStep > 0,
            ),
          ),
          Container(
            width: 24,
            height: 2,
            color: currentStep > 0
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: _StepItem(
              number: '2',
              label: 'Verifikasi',
              active: currentStep == 1,
              completed: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  final bool completed;

  const _StepItem({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = active || completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: highlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text(
                    number,
                    style: TextStyle(
                      color: highlighted
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlighted
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    required this.number,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final XFile? file;
  final VoidCallback onTap;

  const _PhotoField({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = file != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: selected
                        ? Image.file(
                            File(file!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _PhotoPlaceholder(icon: icon),
                          )
                        : _PhotoPlaceholder(icon: icon),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          selected ? Icons.check_rounded : icon,
                          size: 20,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected ? 'Foto siap dikirim' : subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.refresh_rounded
                            : Icons.camera_alt_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final IconData icon;

  const _PhotoPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 30),
        ),
      ),
    );
  }
}
